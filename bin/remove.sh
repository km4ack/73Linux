#! /bin/bash


APPLIST=${BAPDIR}/cache/remove-apps.bap
APPPATH=app/stable/
JOBFILE=${BAPDIR}/cache/joblist.bap
LOGO=$BAPDIR/data/logo.png

#clear;echo;echo
echo "###################################"
echo "#      Welcome $CALL 	"
echo "###################################"

#loops (f)iles for data to put into yad table with checkboxes. BAPP column is lost to checkbox.
# -enhance that BAPP to validate version?
for f in $APPSFILES; do
	vercheck=$(head -6 $f | grep localVer | sed 's/localVer=//')
		if [ "$vercheck" = 0 ]; then
			continue
		fi
    #only accept good files
    CHECKFILE=$(head -c6 $f | sed 's/BAPP=//')
    if [ 1 == 1 ];then
        grep -m 1 -e '^[[:blank:]]*BAPP' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*ID' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Name' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Comment' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*Ver' $f | cut -d = -f 2
        grep -m 1 -e '^[[:blank:]]*localVer' $f | cut -d = -f 2
    fi
done | yad --width=750 --height=500 --title="73 Linux - $BAPCALL" --image=$LOGO \
            --center --list --print-all --search-column=2 --multiple --checklist --grid-lines=hor \
            --column="" --column="ID" --column="App" --column="description" --column="available version" --column="installed version"\
            --text="Select apps to remove. You can sort, or search by typing." --button="Cancel":1 --button="Uninstall":2 | \
           grep TRUE | sed 's/TRUE|//' | cut -f1 -d"|" > $APPLIST
#exported APPLIST write timestamp of this selection to disk
#echo "#$(date +%F-%T) BAP Install List" >> $APPLIST


#this will take the output of above and return it into a string currently similar to the install script list pi-build
#cat file to trim new lines cut to remove the comment at end added by this script
#this matches the legacy way which is used still
APPIDLIST=$(cat $APPLIST | tr '\n' ' ' | cut -f1 -d"#")

if [ -z "$APPIDLIST" ]; then
	echo "#######################################"
	echo "#Nothing selected to uninstall. Exiting 	"
	echo "#######################################"
      sleep 3
      rm $APPLIST
      exit 0
fi

while read -r line; do
file=$(grep ID=${line} $APPSFILES | awk -F ":" '{print $1}')
source $file
REMOVE
done <$APPLIST

exit 0
