#! /bin/bash

echo "#######################################"
echo "#        Welcome to 73 Linux          #"
echo "#######################################"

#variables
BAPDIR="$(cd "$(dirname "$0")" && pwd)"
BAPSYSINFO=${BAPDIR}/cache/cpu.bap
BAPPVER=$(cat ${BAPDIR}/changelog | head -1 | sed 's/version=//')
LOGO=${BAPDIR}/data/logo.png
TEMPCRON=/run/user/$UID/tempcron.txt


APPLIST=${BAPDIR}/cache/app-list.bap
APPPATH=${BAPDIR}/app/stable/
BAPINSTALL=${BAPDIR}/cache/install-path.bap
BUILDDIR=$HOME/.bap-source-files

export BUILDDIR
export LOGO
export BAPDIR

if [ ! -d ${BAPDIR}/cache ]; then
	mkdir ${BAPDIR}/cache
fi

echo "#############################"
echo "Checking for 73 Linux Updates"
echo "#############################"
LATEST=$(curl -s https://raw.githubusercontent.com/km4ack/73Linux/master/changelog | head -1 | sed 's/version=//')
CURRENT=$(grep version ${BAPDIR}/changelog | head -1 | sed 's/version=//')

if (($(echo "${LATEST} ${CURRENT}" | awk '{print ($1 > $2)}'))); then
	echo "#################################"
	echo "A newer version of 73 Linux Found"
	echo "Current version is $CURRENT"
	echo "Latest version is $LATEST"
	echo "############################"
	yad --width=300 --height=150 --fixed --text-align=center --center --title="73 Linux" \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
		--text "Updated version of 73 Linux found.\rInstalled - v${CURRENT}\rLatest - v${LATEST}\rWould you like to update?" \
		--button="Yes":2 \
		--button="No":3
BUT=$?
	if [ $BUT = 252 ]; then
		exit
	elif [ $BUT = 2 ]; then
		wget -q --tries=5 --timeout=10 --spider http://google.com
		if [ $? = 0 ]; then
			cd $HOME
			rm -rf 73Linux
			git clone https://github.com/km4ack/73Linux.git
			yad --width=300 --height=150 --fixed --text-align=center --center --title="73 Linux" \
				--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
				--text "Update complete.\rPlease restart 73 Linux" \
				--button=gtk-ok
		exit
		else
			yad --center --timeout=3 --timeout-indicator=top --no-buttons --text="You are not connected to the internet"
			exit
		fi

	fi

else
	echo "73 Linux up to date. Version $CURRENT installed"
fi

echo "Checking for updated bap files"
CUR=$(grep version ${BAPDIR}/app/.bap-version | sed 's/version=//')
LATEST=$(curl -s https://raw.githubusercontent.com/km4ack/73Linux/master/app/.bap-version | grep version | head -1 | sed 's/version=//')
if (($(echo "${LATEST} ${CUR}" | awk '{print ($1 > $2)}'))); then
	echo "#######################################"
	echo "#    Downloading latest bap files     #"
	echo "#######################################"
	cd /run/user/$UID
	git init 73Linux
	cd 73Linux
	git remote add -f origin https://github.com/km4ack/73Linux.git
	git config pull.ff only
	git config core.sparseCheckout true
	echo "/app" >> .git/info/sparse-checkout
	git pull origin master
	cp -r /run/user/$UID/73Linux/app ${BAPDIR}/
	rm -rf /run/user/$UID/73Linux
else
	echo "bap files up to date"
fi

cd ${BAPDIR}

echo "#######################################"
echo "#  Updating repository & verifying    #"
echo "#  a few needed items needed before   #"
echo "#  we begin.                          #"
echo "#                                     #"
echo "#  Enter your sudo password if asked  #"
echo "#######################################"
sudo apt update
if ! hash yad 2>/dev/null; then
	sudo apt install -y yad
fi

if ! hash jq 2>/dev/null; then
	sudo apt install -y jq
fi

if ! hash bc >/dev/null; then
	sudo apt install -y bc
fi

if ! hash git >/dev/null; then
	sudo apt install -y git
fi

#####################################
#	Verify not run as root
#####################################
if [ `whoami` = 'root' ]; then
	yad --form --width=500 --text-align=center --center --title="73 Linux" --text-align=center \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
		--text="<b>ROOT DETECTED</b>\rDon't run this script as root. \
Restart the script without sudo" \
		--button=gtk-close
	exit 1
fi

touch $HOME/.config/KM4ACK

#first run? welcome!
if [ ! -f "$BAPSYSINFO" ]; then
    
    # Detect if the script is part of a full source checkout or standalone instead.
    if [ ! -f "${BAPDIR}/app/stable/autohotspot" ]; then
        echo -e "\n Missing important stuff. Can't continue. "
        exit 1
    fi

    #create source repo
    mkdir -p ${HOME}/.bap-source-files

    #set the station call sign
    N0CALL=$(yad --form --width=420 --text-align=center --title="73 Linux" --center \
        --title="Amature Radio Callsign Required" --center --image="$LOGO" \
        --field="Call Sign" \
        --field="<b>Required</b>":LBL)

    #input validate
    TMPCALL=$(echo "${N0CALL^^}" | sed 's/||//' | awk '{gsub(/[^[:alnum:][:space:]]/,"?")} 1')

    if echo "$TMPCALL" | grep -q "?";then
        echo -e "\n ERROR: CRITICAL: valid call to operate (no SSID) $TMPCALL QRZ?"
        exit 1
    fi

    #blank check
    if [ $N0CALL = "||" ] || [ $N0CALL = "" ]; then
        echo -e "\n ERROR: CRITICAL: need a radio call to operate, nothing heard QRZ?"
        exit 1

    else
        #save
        MYCALL=$TMPCALL
        BAPCALL=$TMPCALL
        touch ${BAPDIR}/MYCALL.$MYCALL
        touch ${BAPDIR}/cache/MYCALL.$MYCALL
        echo "###################################"
        echo "#Registered $MYCALL to this host"
        echo "###################################"
        wait
    fi

    # Setup the other CPU data we will need make it global for this session
    if [ -f ${BAPDIR}/bin/set-enviroment.sh ]; then
        echo "###################################"
        echo "#Detected New System for Install"
        echo "###################################"
        echo -e "Hostname - $(hostname -s)"
        ${BAPDIR}/bin/set-enviroment.sh
    else
            echo -e "\n ERROR: CRITICAL: check integrity of package."
            exit 1
    fi

    # Show once dialog
    yad --form --width=420 --height=200 --fixed --center --title="Welcome ${MYCALL}!" --image="$LOGO"  \
    --image-on-top --text-align=fill --button=gtk-ok --text="\n          <b>${MYCALL} DE KM4ACK!</b>\r        Welcome to\r
                    <b>73 Linux</b>\n
        Build a Pi on Steroids!\n
            -A full build can take up to 4 hours!
	    -Possibly more on a Pi 3
	    -Press ok to scan the system
	     and begin the build process"

    #fi first run, wait
    wait

#Give option to load community apps. Call config script
else
	${BAPDIR}/bin/config.sh
fi

COMMUNITY_CK=$(ls -a ${BAPDIR}/cache/ | grep .community)
if [ -z $COMMUNITY_CK ]; then
	echo "Community apps excluded"
else
	echo "Community Apps included"
	rm ${BAPDIR}/cache/.community
fi

#set up variables for use globally here
BAPARCH=$(echo $(sed '1q;d' $BAPSYSINFO))
BAPCORE=$(echo $(sed '2q;d' $BAPSYSINFO))
BAPCPU=$(echo $(sed '3q;d' $BAPSYSINFO))
BAPDIST=$(echo $(sed '4q;d' $BAPSYSINFO))
BAPSRC=$(echo ${HOME}/.bap-source-files)
echo $BAPDIR > $BAPINSTALL
BAPCALL=$(ls ${BAPDIR}/cache | grep MYCALL.* | sed 's/MYCALL.//')
MYCALL=$BAPCALL
CALL=$BAPCALL

#LOAD_FILES=$(echo $BAPCPU | grep arm)
#Determine if to include community apps
#if [ -z "$LOAD_FILES" ] && [ -n "$COMMUNITY_CK" ]; then
#	APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp ${BAPDIR}/app/community/x86_64/*.bapp"
#elif [ -z $LOAD_FILES ]; then
#	APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp"
#elif [ -n $LOAD_FILES ] && [ -n "$COMMUNITY_CK" ]; then
#	APPSFILES="${BAPDIR}/app/stable/pi/*.bapp ${BAPDIR}/app/community/pi/*.bapp"
#elif [ -n $LOAD_FILES ]; then
#	APPSFILES="${BAPDIR}/app/stable/pi/*.bapp"
#fi

LOAD_FILES=$(lscpu | grep Architecture: | awk '{print $2}')

case $LOAD_FILES in
	armv7l)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp ${BAPDIR}/app/community/pi/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp"
		fi;;
	aarch64)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp ${BAPDIR}/app/community/pi/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/pi/*.bapp"
		fi;;
	x86_64)
		if [ -n "$COMMUNITY_CK" ]; then
			APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp ${BAPDIR}/app/community/x86_64/*.bapp"
		else
			APPSFILES="${BAPDIR}/app/stable/x86_64/*.bapp"
		fi;;

esac

export BAPCPU
export BAPCORE
export BAPARCH
export BAPDIST
export BAPCALL
export MYCALL
export CALL
export BAPSRC
export BAPSYSINFO
export BAPPVER
export APPSFILES
export TEMPCRON
export LOGO

#check for updates
${BAPDIR}/bin/app-check.sh
wait

   #jump to uninstall
UNINSTALL_CK=$(ls -a ${BAPDIR}/cache/ | grep .remove)
   if [ -n "$UNINSTALL_CK" ]; then
	rm ${BAPDIR}/cache/.remove
	${BAPDIR}/bin/remove.sh
	wait
	exit
   fi

#launch menu
${BAPDIR}/bin/menu.sh
wait
