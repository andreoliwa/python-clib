#!/bin/bash

# Always start Dropbox before going away
V_PID_DROPBOX="$(pidof dropbox)"
if [ -z "$V_PID_DROPBOX" ] ; then
	dropbox start
fi

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	backup-full.sh -f
fi

# Close gracefully
# http://how-to.wikia.coim/wiki/How_to_gracefully_kill_(close)_programs_and_processes_via_command_line
for V_GRACE in pidgin skype rhythmbox ; do
	echo "Killing $V_GRACE"
	if [ -n "$(pidof $V_GRACE)" ] ; then
		kill -s sigterm $(pidof $V_GRACE)
		sleep 4
	else
		pkill $V_GRACE
	fi
done

# Show download folder if not empty (ignoring hidden files and dirs)
[ $(find $G_DOWNLOAD_DIR -type f -not -wholename '*/.*/*' | wc -l) -ne 0 ] && xdg-open $G_DOWNLOAD_DIR

backup-config.sh

safe-remove.sh -d black
safe-remove.sh -d m3

sudo /usr/local/bin/noip2

if [ -z "$V_PID_DROPBOX" ] ; then
	# If Dropbox wasn't started, then wait some time for it to load properly
	echo 'Waiting for Dropbox to start...'
	sleep 5
fi

# At home, wait until everything is synced before shutting Dropbox down
dropbox-shutdown.sh
