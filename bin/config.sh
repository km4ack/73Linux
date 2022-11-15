#!/bin/bash

MAIN(){
	INFO=$(yad --form --width=420 --fixed --text-align=center --center --title="73 Linux" \
		--image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
		--text="Community apps can be written by anyone\r and included alongside the core \
apps but may\rcause 73 Linux to not run as expected.\r<b>PROCEED WITH CAUTION!</b>\rand only load apps from trusted sources" \
		--field="Include Community Apps?":CHK \
		--button="Uninstall Apps":4 \
		--button="Learn More":3 \
		--button="Select Apps for Build":2)
	BUT=$?
	EXP=$(echo $INFO | awk -F "|" '{print $1}')
	REMOVE=$(echo $INFO | awk -F "|" '{print $2}')
	if [ "$EXP" = 'TRUE' ]; then
		touch ${BAPDIR}/cache/.community
	fi

	case $BUT in
	    4)  echo "Loading uninstall script"
		touch ${BAPDIR}/cache/.remove
		;;
	    3)
		xdg-open https://groups.io/g/KM4ACK-Pi/topics >/dev/null 2>&1 &
		ID=$(ps aux | grep 73.sh | head -1 | awk '{print $2}')
		kill $ID
		exit
		;;
	    2)		
		echo "Loading build script"
		;;
	    252)
		ID=$(ps aux | grep 73.sh | head -1 | awk '{print $2}')
		kill $ID
		exit
		;;

	esac
}


MAIN