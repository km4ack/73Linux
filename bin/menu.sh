#! /bin/bash

APPLIST=${BAPDIR}/cache/installed-apps.bap
APPPATH=app/stable/
JOBFILE=${BAPDIR}/cache/joblist.bap
LOGO=$BAPDIR/data/logo.png
export JOBFILE
#clear;echo;echo
echo "###################################"
echo "#      Welcome $CALL 	"
echo "###################################"

#loops (f)iles for data to put into yad table with checkboxes. BAPP column is lost to checkbox.
# -enhance that BAPP to validate version?
for f in $APPSFILES; do
    #only accept good files
    CHECKFILE=$(head -c6 $f | sed 's/BAPP=//')
    CURBAPVER=$(grep version ${BAPDIR}/changelog | head -1 | sed 's/version=//' | cut -b 1)
    if [ $CHECKFILE == $CURBAPVER ];then
        grep -m 1 -e '^[[:blank:]]*BAPP' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*ID' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Name' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Comment' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Ver' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*localVer' $f | cut -d = -f 2
    fi
done | yad 2> /dev/null --width=750 --height=500 --title="73 Linux - $BAPCALL" --image=$LOGO \
            --center --list --print-all --search-column=2 --multiple --checklist --grid-lines=hor \
            --column="" --column="ID" --column="App" --column="description" --column="available version" --column="installed version"\
            --text="Select apps to install you can sort, or search by typing. Detected: $BAPARCH bit $BAPDIST" --button="Cancel":1 --button="Build It":2 | \
           grep TRUE | sed 's/TRUE|//' | cut -f1 -d"|" > $APPLIST
#exported APPLIST write timestamp of this selection to disk
#echo "#$(date +%F-%T) BAP Install List" >> $APPLIST

#this will take the output of above and return it into a string currently similar to the install script list pi-build
#cat file to trim new lines cut to remove the comment at end added by this script
#this matches the legacy way which is used still
APPIDLIST=$(cat $APPLIST | tr '\n' ' ' | cut -f1 -d"#")

if [ -z "$APPIDLIST" ]; then
	echo "######################################"
	echo "#Nothing selected to install. Exiting 	"
	echo "######################################"
	sleep 2
	exit 0
fi

#processing for jobs to run

#grep all .bapp files and find the matching APP-ID from selection and return .bapp file name for processing
runlist=$(egrep $APPSFILES -m 1 -e $(echo $APPIDLIST | sed 's/ /|/g') | cut -f1 -d":" )

#cat $runlist > $JOBLIST
#create a runlist file just as printed above but as a sting for processing
echo $runlist | sed 's/ /\n/' > $JOBFILE
JOBLIST=$(echo $runlist | sed 's/ /\n/')


#Set Variables in global
export APPIDLIST
export JOBLIST
export runlist
export APPLIST

#echo -e "\n Apps to install $APPIDLIST"
#echo -e "\n Files to process now:\n\n$runlist\n"
#echo -e "\n CPU core for make -j$(sed '2q;d' $BAPSYSINFO) \n"
${BAPDIR}/bin/runner.sh

exit 0
