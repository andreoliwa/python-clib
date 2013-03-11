#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
Calculates the difference between times.
When starting and ending times are supplied, return the time difference in seconds.
When no starting and ending times are supplied, read data from STDIN.

-s  Starting time
-e  Ending time
-h  Help"
	exit $1
}

V_START_TIME=
V_END_TIME=
while getopts "s:e:h" V_ARG ; do
	case $V_ARG in
	s)	V_START_TIME=$OPTARG ;;
	e)	V_END_TIME=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 1 ;;
	esac
done

if [ -n "$V_START_TIME" -a -n "$V_END_TIME" ] ; then
	V_TIME1=$(date -d "$V_START_TIME" +"%s")
	V_TIME2=$(date -d "$V_END_TIME" +"%s")
	V_DIFF_SECONDS=$(($V_TIME2-$V_TIME1))
	echo $V_DIFF_SECONDS
	exit
fi

# http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script
V_OLD_IFS=$IFS
IFS='
'
V_PREVIOUS=0
for V_LINE in $(cat) ; do
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
