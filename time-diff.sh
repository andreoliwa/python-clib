#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
Calcula a diferenca entre horarios.

  -h   Ajuda"
	exit $1
}

while getopts "h" OPTION ; do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit
		;;
	esac
done

# http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script
V_OLD_IFS=$IFS
IFS='
'
V_PREVIOUS=0
for V_LINE in $(cat); do
	V_SECONDS=$(echo "$V_LINE" | cut -b 12-19 | awk '
	function convert_hms_to_seconds( time_hms ) {
		split( time_hms , piece , ":" )
		return piece[1] * 3600 + piece[2] * 60 + piece[3]
	}
	{ print convert_hms_to_seconds( $1 ) }')

	if [ $V_PREVIOUS -eq 0 ] ; then
		V_DIFF=0
	else
		V_DIFF=$(($V_SECONDS-$V_PREVIOUS))
	fi

	if [ $V_DIFF -eq 0 ] ; then
		echo '--:--:-- - '$V_LINE
	else
		echo $(date -u -d @"$V_DIFF" +'%-0H:%-0M:%-0S')' - '$V_LINE
	fi

	V_PREVIOUS=$V_SECONDS
done
IFS=$V_OLD_IFS
