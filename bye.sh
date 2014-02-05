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

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	# Copies the "Standards Documentation" to the QA directory
	V_PDF_SOURCE_DIR=/net/srvfol1/groups/desenvolvimento
	V_PDF_DEST_DIR=$G_DROPBOX_DIR/src/home-office/dev_bin/devqa/_archive
	for V_PDF in $V_PDF_SOURCE_DIR/*.pdf ; do
		V_BASENAME=$(basename "$V_PDF")
		cp -uv "$V_PDF" "$V_PDF_DEST_DIR"/$(normalize.sh -s $V_BASENAME)
	done

	# Start resource-consuming applications before going home
	[ -n "$(type -p deluge-gtk)" ] && deluge-gtk &

	xdg-open $G_WORK_TIMECLOCK_URL &
	zenity --warning --text="For safety reasons, please put the headphones inside the drawer."

	# Search for 'Trash' directories I might have left in the servers
	[ -d /net/ ] &&	V_FIND=$(find /net/ -maxdepth 3 -type d -name '.Trash-*') && [ -n "$V_FIND" ] && echo "$V_FIND" | xargs xdg-open
else
	sudo /usr/local/bin/noip2

	if [ -z "$V_PID_DROPBOX" ] ; then
		# If Dropbox wasn't started, then wait some time for it to load properly
		echo 'Waiting for Dropbox to start...'
		sleep 5
	fi

	# At home, wait until everything is synced before shutting Dropbox down
	dropbox-shutdown.sh
fi
