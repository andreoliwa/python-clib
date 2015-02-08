#!/bin/bash
echo 'Gravando log de janelas ativas...'

# Empty line on log
V_LOGFILE=$HOME/.gtimelog/$(basename $0).log
echo >> $V_LOGFILE

LAST=
while true ; do
	CURRENT=$(wmctrl -lpx | grep " $(xdotool getactivewindow getwindowpid) " 2> /dev/null)
	# CURRENT=$(xdotool getactivewindow getwindowname 2> /dev/null)
	if [ "$CURRENT" != "$LAST" ] ; then
		LAST=$CURRENT
		LOG="$(date '+%Y-%m-%d %H:%M:%S'): $LAST"
		# echo $LOG
		echo $LOG >> $V_LOGFILE
	fi

	sleep 1
done
