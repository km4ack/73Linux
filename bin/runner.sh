#!/bin/bash

CONFIG=${BAPDIR}/cache/config.txt
mkdir -p ${BAPDIR}/cache/logs/
LOG=${BAPDIR}/cache/logs/build-log.txt
touch $LOG
touch ${HOME}/Documents/mylog.txt
crontab -l > $TEMPCRON

export CONFIG
export LOG

FINISH(){
	echo "cleaning up"
	rm ${BUILDDIR}/*.gz /run/user/$UID/pw.txt /run/user/$UID/pw.p >/dev/null 2>&1
	mv $LOG "$LOG-`date`.txt"
}
trap FINISH EXIT

#add data to log file
echo "BAPCPU=$BAPCPU" >> $LOG
echo "BAPCORE=$BAPCORE" >> $LOG
echo "BAPARCH=$BAPARCH" >> $LOG
echo "BAPDIST=$BAPDIST" >> $LOG
echo "BAPDIR=$BAPDIR" >> $LOG
echo "BAPCALL=$BAPCALL" >> $LOG
echo "MYCALL=$MYCALL" >> $LOG
echo "CALL=$CALL" >> $LOG
echo "BAPSRC=$BAPSRC" >> $LOG
echo "BAPSYSINFO=$BAPSYSINFO" >> $LOG
echo "BAPPVER=$BAPPVER" >> $LOG
echo "APPSFILES=$APPSFILES" >> $LOG
echo "TEMPCRON=$TEMPCRON" >> $LOG
echo "#############################" >> $LOG
echo "#APPS TO BE INSTALLED" >> $LOG
echo "#############################" >> $LOG
cat $APPLIST >> $LOG
echo "#############################" >> $LOG
echo "@reboot sleep 10 && export DISPLAY=:0 && ${BAPDIR}/bin/.complete" >> $TEMPCRON
	
	#reset the config file
	if [ -f "$CONFIG" ]; then
		rm $CONFIG
	fi

	#set wallpaper accoreding to arch
	ARCH_CK=$(echo $BAPCPU | grep arm)
	if [ -z $ARCH_CK ]; then
		gsettings set org.gnome.desktop.background picture-uri file:///${BAPDIR}/data/bap-wallpaper.jpg
		CORE=${BAPDIR}/app/stable/x86_64/*.bapp
	else
		CORE=${BAPDIR}/app/stable/pi/*.bapp
		sudo cp ${BAPDIR}/data/bap-wallpaper.jpg /usr/share/rpd-wallpaper/
		pcmanfm --set-wallpaper /usr/share/rpd-wallpaper/bap-wallpaper.jpg
	fi

#define core apps
echo "ARDOP ARDOPGUI AX25 BATT BPQ CHIRP CONKY CQRLOG DIPOLE DIREWOLF EES FLAMP FLDIGI FLMSG FLNET FLRIG FLWRAP GARIM \
	GPREDICT GPS GPSUPDATE GRIDCALC GRIDTRACKER HAMCLOCK HAMLIB HAMRS HOTSPOT HSTOOLS JS8 M0IAX PAT PATMENU PIAPRS PIQSO PISTATS \
	PITERM QTSOUND REPEAT SECURITY SHOWLOG TQSL VARA VNC WSJTX XASTIR XYGRIB YAAC" > ${BAPDIR}/cache/core.bapps

	for file in ${CORE}; do
		ck_file=$(echo $file | awk -F "/" '{print $NF}' | sed 's/.bapp//')
		CK=$(grep $ck_file ${BAPDIR}/cache/core.bapps)
			if [ -z "$CK" ]; then
				mkdir -p ${BAPDIR}/app/not-core-files/
				mv ${file} ${BAPDIR}/app/not-core-files/
			fi
	done
rm ${BAPDIR}/cache/core.bapps

#If VARA is chosen, make sure we have a Pi 4 32 bit system to work with. 
#As of 02OCT2022 the VARA installer only works with the Pi 4.
VARA_CHK=$(grep VARA ${APPLIST})
if [ -n "$VARA_CHK" ]; then
	FREEMEM=$(free -m | grep Mem: | awk '{ print $2 }')
	if [ $FREEMEM -lt 1500 ]; then
	echo "Not enough memory available"
	yad --form --width=500 --text-align=center --center --title="73 Linux" --text-align=center \
	--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
	--text="<b>Not enough memory</b>\rVARA requires a Pi 4.\r\rVARA will not be installed during the build." \
	--button=gtk-ok
	sed -i 's/VARA//;/^$/d' ${APPLIST}
	fi

fi

#Get hotspot date if installing hotspot
HSCK=$(grep "HOTSPOT" ${APPLIST})
if [ -n "$HSCK" ]; then
echo "#############################"
echo "Scanning for nearby WiFi....."
echo "#############################"
	HSINFO() {
		#unblock wifi
		sudo rfkill unblock all >/dev/null 2>&1
		#bring wifi up
		sudo ifconfig wlan0 up
		LIST=$(sudo iw dev "wlan0" scan ap-force | sed -ne 's/^.*SSID: \(..*\)/\1/p' | sort | uniq | paste -sd '|')

		HSINFO=$(yad --center --form --width=400 --height=400 --separator="|" --item-separator="|" \
			--image ${LOGO} --column=Check --column=App --column=Description \
			--window-icon=${LOGO} --image-on-top --text-align=center \
			--text="<b>HotSpot Information\r\rPlease enter the information\rbelow \
for the Hot Spot\r</b>NOTE: The last field is the password for the hotspot. You will use this password to \
connect to your Pi when it is in hotspot mode <b>This password can only contain letters and numbers</b>" \
			--title="73 Linux" \
			--field="Home Wifi SSID":CB "$LIST" \
			--field="Home Wifi Password":H \
			--field="Hot Spot Password" \
			--button="Exit":1 \
			--button="Continue":2 \
			--button="Refresh Wifi":3)
		BUT=$?
		if [ ${BUT} = 3 ]; then
			HSINFO #Call HSINFO function
		fi

		if [ ${BUT} = 252 ] || [ ${BUT} = 1 ]; then
			exit
		fi
		#}
		#HSINFO
		#fi
		SHACKSSID=$(echo $HSINFO | awk -F "|" '{print $1}')
		SHACKPASS=$(echo $HSINFO | awk -F "|" '{print $2}')
		HSPASS=$(echo $HSINFO | awk -F "|" '{print $3}')

		#Check password length
		if [ -n "$HS" ]; then
			COUNT=${#HSPASS}
			if [ ${COUNT} -lt 8 ]; then
				yad --center --form --width=300 --height=200 --separator="|" \
					--image ${LOGO} --window-icon=${LOGO} --image-on-top --text-align=center \
					--text="<b>Hotspot password has to be 8-63 characters</b>" --title="73 Linux" \
					--button=gtk-ok
				HSINFO
			fi
		fi

	}
	HSINFO
fi

echo "SHACKSSID=$SHACKSSID" >>${CONFIG}
echo "SHACKPASS=\"$SHACKPASS\"" >>${CONFIG}
echo "HSPASS=\"$HSPASS\"" >>${CONFIG}

#Get GPS data if installing GPS
GPSCK=$(grep -w GPS $APPLIST)
if [ -n "${GPSCK}" ]; then

	yad --center --height="300" --width="300" --form --separator="|" --item-separator="|" --title="GPS" \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top \
		--text="\r\r\r\r\r<b><big>Connect your GPS to the computer</big></b>" \
		--button="Continue":2

	BUT=$?

	USB=$(ls /dev/serial/by-id)
	USB=$(echo "NONE $USB") #see https://github.com/km4ack/pi-build/issues/293
	USB=$(echo $USB | sed "s/\s/|/g")

	GPS=$(yad --center --height="600" --width="300" --form --separator="|" --item-separator="|" --title="GPS" \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top \
		--text="Choose Your GPS" \
		--field="GPS":CB "$USB")
	BUT=$?
	if [ ${BUT} = 252 ] || [ ${BUT} = 1 ]; then
		echo exiting
		exit
	fi

	GPS=$(echo ${GPS} | awk -F "|" '{print $1}')
	GPS=/dev/serial/by-id/${GPS}
	echo "GPS=${GPS}" >>${CONFIG}
fi

#get info if installing Pat Winlink
PATCK=$(grep -w PAT $APPLIST)
if [ -n "$PATCK" ]; then
	INFO=$(yad --form --width=420 --text-align=center --center --title="Winlink Settings" \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
		--text="73 Linux\r<b>version $BAPPVER</b>\rWinlink Settings" \
		--field="Six Character Grid Square" \
		--field="Winlink Password":H \
		--field="<b>Password is case sensitive</b>":LBL \
		--button="Continue":2)
	GRID=$(echo ${INFO} | awk -F "|" '{print $1}')
	GRID=${GRID^^}
	WL2KPASS=$(echo ${INFO} | awk -F "|" '{print $2}')
	echo "GRID=$GRID" >>${CONFIG}
	echo "WL2KPASS=\"$WL2KPASS\"" >>${CONFIG}
fi

	#####################################
	#	Get User PW
	#####################################
MYPASS(){
   	MYPASS=$(yad --form --width=420 --text-align=center --center \
        --title="Sudo Password" --center --image="$LOGO" \
        --field="Sudo Password":h \
	--field="Sudo Password":h \
        --field="<b>Required</b>":LBL)

	mypass1=$(echo $MYPASS | awk -F "|" '{print $1}')
	mypass=$(echo $MYPASS | awk -F "|" '{print $2}')

		if [ "$mypass" != "$mypass1" ]; then
		    	yad --form --width=420 --text-align=center --center \
			--title="SUDO Password" --center --image="$LOGO" \
			--text="\r\r<b>Password doesn't match. Try again</b>" \
			--button=gtk-ok
		MYPASS
		fi
}
MYPASS

	echo "$mypass" | base64 > /run/user/$UID/pw.p

	#create file for sudo askpass
	touch /run/user/$UID/pw.txt
	echo '#!/bin/bash' > /run/user/$UID/pw.txt
	echo 'PASS=$(base64 -d /run/user/$UID/pw.p)' >> /run/user/$UID/pw.txt
	echo 'echo $PASS' >> /run/user/$UID/pw.txt
	chmod +x /run/user/$UID/pw.txt
	SUDO_ASKPASS=/run/user/$UID/pw.txt
	export SUDO_ASKPASS


	#reset sudo timer to prevent false positive
	sudo -k

	echo "Checking SUDO credentials....standby"
	sudo -A touch /run/user/$UID/sutest 2>&1 </dev/null

	if [ $? = 1 ]; then
		echo "Wrong sudo password entered. Can't continue! Exiting"
		exit
	else 
		echo "Credentials check out....continuing"
	fi

	##################################
	#	INCREASE SWAP
	##################################
	#find how much memory we are working with
	FREEMEM=$(free -m | grep Mem: | awk '{ print $2 }')
	echo ${FREEMEM}

	#increase swap file if less than 3G memory
	if [ ${FREEMEM} -lt 3000 ]; then
		echo "##############################"
		echo "Increasing Swap size for build"
		echo "##############################"
		#increase swap size
		sudo sed -i 's/#CONF_SWAPFILE=\/var\/swap/CONF_SWAPFILE=\/var\/swap/' /etc/dphys-swapfile
		sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
		sudo /etc/init.d/dphys-swapfile restart
		sleep 10
	fi

	sudo -A apt upgrade -y
	#below may be needed on x86 builds and does no harm if already installed.
	sudo -A apt install build-essential git curl -y
	sudo -A mkdir -p /usr/local/share/applications
	
	mkdir -p ${HOME}/.config/autostart
	##################################
	#	Misc Setup
	##################################
	#add virtual sound card link for pulse audio
	cd ${HOME} || ! echo "Failure"
cat >tempsound <<EOF
pcm.pulse {
	type pulse
	}
ctl.pulse {
	type pulse
	}
EOF
	sudo -A chown root:root tempsound
	sudo -A mv tempsound /etc/asound.conf

	#mod sound card for Buster May 2020
	#so it will always load as card #3
	cd ${HOME}
cat >tempsound <<EOF
#Internal sound
options snd-bcm2835 index=0

#USB soundcard
options snd-usb-audio index=3
EOF
	sudo -A chown root:root tempsound
	sudo -A mv tempsound /etc/modprobe.d/alsa.conf

	#install ham radio menu
	sudo -A apt install -y extra-xdg-menus

	#setup bin dir and put in path
	mkdir -p ${HOME}/bin
	# Add $HOME/bin to PATH
	# Prevent adding it more than once
	# Prevent adding it if already added elswhere
	if ! grep -q 'export PATH=$PATH:$HOME/bin' "${HOME}/.bashrc" && [[ ! "${PATH}" =~ "${HOME}/bin" ]]; then
		echo 'export PATH=$PATH:$HOME/bin' >> "${HOME}/.bashrc"
	fi

	##################################
	#file sorting
	##################################
TEMP=${BAPDIR}/cache/tempjoblist.txt
#move these files to top of list so they get built first
APPS=(HAMLIB GPSUPDATE GPS DIREWOLF HOTSPOT)

	for i in "${APPS[@]}"; do
		CK=$(grep -i -w $i $APPLIST)
            if [ -n "${CK}" ]; then
                sed -i "/${CK}/d" $APPLIST
                echo "${CK}" >>$TEMP
            fi
	done

#grab everything left in the job file
cat $APPLIST >> $TEMP

#move vara to the bottom of the list!
#this is needed b/c current build of VARA on x86_64 requires user interaction.
#once it asks for user input, the script will only be about 10 minutes or less
#to complete.
grep -i VARA $TEMP >/dev/null 2>&1
    if [ $? = 0 ]; then
        sed -i "/VARA/d" $TEMP
        echo "VARA" >> $TEMP
    fi

#recreate master list with new build order
mv $TEMP $APPLIST

	#####################
	#fun facts
	#####################
	${BAPDIR}/bin/./.funfacts &

	##################################
	#loop through and install files
	##################################
	while read -r line; do
		file=$(grep ID=${line} $APPSFILES | awk -F ":" '{print $1}')
		source $file
		echo "##########################" | tee -a $LOG
		echo "Installing $ID"	| tee -a $LOG
		echo "##########################" | tee -a $LOG
		INSTALL | tee -a $LOG
		cd ${BAPDIR}
	done <$APPLIST

	##################################
	#	RESET SWAP
	##################################

	#reset swap size to default
	if [ ${FREEMEM} -lt 3000 ]; then
		echo "##############################"
		echo "Resetting swap size to default"
		echo "##############################"
		#reset swap size
		sudo sed -i 's/CONF_SWAPFILE=\/var\/swap/#CONF_SWAPFILE=\/var\/swap/' /etc/dphys-swapfile
		sudo sed -i 's/CONF_SWAPSIZE=1024/CONF_SWAPSIZE=100/' /etc/dphys-swapfile
		sudo /etc/init.d/dphys-swapfile restart
	fi


	##################################
	#	Clean Up
	##################################
	if uname -m | grep arm; then
		sudo apt remove -y libhamlib4
	fi

	${BAPDIR}/bin/menu-update
	rm ${BUILDDIR}/*.gz /run/user/$UID/pw.txt /run/user/$UID/pw.p >/dev/null 2>&1
	mv $LOG "$LOG-`date`.txt"
	crontab $TEMPCRON
	echo "Build log - ${BAPDIR}/cache/logs/"
	echo "#######################################"
	echo "# Build complete. A reboot is needed. #"
	echo "# If you close this window, you will  #"
	echo "# need to reboot manually.            #"
	echo "#######################################"

#reboot when done
yad --width=400 --height=200 --title="Reboot" --image ${LOGO} \
	--text-align=center --skip-taskbar --image-on-top \
	--wrap --window-icon=${LOGO} \
	--undecorated --text="<big><big><big><b>Build complete \rReboot Required</b></big></big></big>\r\r" \
	--button="Reboot Now":0 \
	--button="Exit":1
BUT=$?

	if [ ${BUT} = 0 ]; then
		echo rebooting
		reboot
	elif [ ${BUT} = 1 ]; then
		exit
	fi




