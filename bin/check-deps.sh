#! /bin/bash
# ------------------------------------------------------------------
# checks job files for any missed required apps to also be added
# ------------------------------------------------------------------
VERSION=0.6.0a

APPLIST=./cache/app-list.bap
APPPATH=app/stable/
APPSFILES=app/stable/*.bapp
JOBFILE=./cache/joblist.bap

echo "###################################"
echo "#	Checking for Dependcies "
echo "###################################"

for Job in $JOBLIST; do  
    #keep a eye on things
    trap 'catch' ERR
    catch() {
	echo -e "\nCRITICAL: parsing error on .bapp $Job"
	}
    
    #Check and eval dep from .bapp files
    source $Job
    DEPENDS
    echo -e "INFORMATIONAL: Processing: $Job:"

	#if missing handle
    if [ ! -z $NEEDED ];then
	MISSING=$(egrep -e "$NEEDED" data/base-apps.bap)
	echo -e "INFORMATIONAL: Required: $NEEDED"

	for MDEP in $MISSING;do
		#check that we didnt forget to install base app
		if [ ! -z "$MISSING" ];then
			echo -e "\n CRITIAL: missing dependency $MDEP needs resolved"

			yad  --width=420 --height=100 --center --fixed --text-align=center --title $Job \
			--text="CRITICAL: missing dependency $MDEP\n unable to handle error at this time\n
			please run again selecting the missing packages manually for now.\n
			bapp file error: $Job"
		fi
	done

    else
		echo -e "INFORMATIONAL: no dependencies\n"
    fi
    wait
done    
