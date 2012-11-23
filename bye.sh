#!/bin/bash

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	backup-full.sh -f
fi

# Close gracefully
# http://how-to.wikia.coim/wiki/How_to_gracefully_kill_(close)_programs_and_processes_via_command_line
for V_GRACE in pidgin rhythmbox ; do
	echo "Killing $V_GRACE"
	if [ -n "$(pidof $V_GRACE)" ] ; then
		kill $(pidof $V_GRACE)
		#-s INT
	fi
	pkill $V_GRACE
done

# Show download folder if not empty
[ $(find $G_DOWNLOAD_DIR -type f | wc -l) -ne 0 ] && nautilus $G_DOWNLOAD_DIR

# Search for 'Trash' directories I might have left in the servers
[ -d /net/ ] &&	V_FIND=$(find /net/ -maxdepth 3 -type d -name '.Trash-*') && [ -n "$V_FIND" ] && echo "$V_FIND" | xargs nautilus

backup-config.sh

for V_MEDIA in $(find /media/ -maxdepth 2 -type d -name '*samsung*' 2> /dev/null) ; do
	echo "Unmounting $V_MEDIA"
	sudo umount $V_MEDIA

	V_LABEL=$(basename $V_MEDIA)
	V_DEVICE=$(sudo blkid -L $V_LABEL)
	echo "Safely removing $V_LABEL (${V_DEVICE%?})"
	udisks --detach ${V_DEVICE%?}
done

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	# Copies the "Standards Documentation" to the QA directory
	V_PDF_SOURCE_DIR=/net/srvfol1/groups/desenvolvimento
	V_PDF_DEST_DIR=~/Dropbox/src/home-office/dev_bin/devqa/_archive
	for V_PDF in $V_PDF_SOURCE_DIR/*.pdf ; do
		V_BASENAME=$(basename "$V_PDF")
		cp -uv "$V_PDF" "$V_PDF_DEST_DIR"/$(normalize.sh -s $V_BASENAME)
	done

	# Start resource-consuming applications before going home
	dropbox start
	[ -n "$(type -p deluge-gtk)" ] && deluge-gtk &

	google-chrome http://ponto.cpndin.com.br/ &
	zenity --warning --text="For safety reasons, please put the headphones inside the drawer."
fi
