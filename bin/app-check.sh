#! /bin/bash

APPLIST=./cache/app-list.bap
APPPATH=app/stable/
allAPPS=$(ls $APPSFILES)
mkdir -p ${BAPDIR}/cache/logs/
LOG=${BAPDIR}/cache/logs/build-log.txt
export LOG
touch $LOG

echo "###################################"
echo "# Verifying .bapp Plug-Ins "
echo "###################################"
for files in ${BAPDIR}/app/**/**/*.bapp; do
	source $files >/dev/null 2>&1
	if [ $? != 0 ]; then
		newfile=$(echo $files | sed 's/.bapp//')
		mv $files $newfile
		echo "Bad bap file found. Removing" | tee -a $LOG
		echo "$files" | tee -a $LOG
		echo "###################################" | tee -a $LOG
	fi
done

echo "###################################"
echo "# Scanning .bapp Plug-Ins "
echo "###################################"
for Job in $allAPPS
do
    #keep a eye on things
    trap 'catch' ERR
    catch() {
	echo -e "\nCRITICAL: parsing error on .bapp $Job" | tee -a $LOG
	}

	CHECKFILE=$(head -c6 $Job | sed 's/BAPP=//')
	CURBAPVER=$(grep version ${BAPDIR}/changelog | head -1 | sed 's/version=//' | cut -b 1)
	if [ $CHECKFILE == $CURBAPVER ];then
		#get the version function ran to have access here
		source $Job
		
		#pull function from file
		echo "###################################"
		echo "#Check Version  $ID 	"
		echo "###################################"
        VERSION
		#Status Update for CLI and GUI
		if (($(echo "${NEWVER} ${CURRENT}" | awk '{print ($1 > $2)}'))); then
			echo -e "UPDATE: $NEWVER is available and $CURRENT is installed"

			#update .bapp with new data gathered from .bapp VERSION function
			sed -i "s/Ver=.*/Ver=Update:$NEWVER/" $Job
        	else
            		sed -i "s/Ver=.*/Ver=$NEWVER/" $Job
		fi

		#this fella is down here to keep order for yad GUI
		sed -i "s/localVer=.*/localVer=$CURRENT/" $Job
	fi
	#clear values
	NEWVER=0.0
	CURRENT=0.0
 

done

