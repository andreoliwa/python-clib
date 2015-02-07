#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Safely remove external hard disks.

OPTIONS
-d  Device name to remove (or part of the name)
-n  Dry-run
-h  Help"
	exit $1
}

V_DEVICE_NAME=
V_DRY_RUN=
while getopts "d:nh" V_ARG ; do
	case $V_ARG in
	d)	V_DEVICE_NAME=$OPTARG ;;
	n)	V_DRY_RUN='(DRY-RUN) ' ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done
if [ -z "$V_DEVICE_NAME" ] ; then
	usage 3
fi

V_OLD_IFS=$IFS
IFS='
'
for V_MEDIA in $(find /media/ -maxdepth 2 -type d -iname "*$V_DEVICE_NAME*" 2> /dev/null) ; do
	echo "${V_DRY_RUN}Unmounting $V_MEDIA"
	[ -z "$V_DRY_RUN" ] && sudo umount "$V_MEDIA"

	V_LABEL=$(basename "$V_MEDIA")
	V_DEVICE=$(sudo blkid -L "$V_LABEL")
	echo "${V_DRY_RUN}Safely removing $V_LABEL (${V_DEVICE%?})"
	[ -z "$V_DRY_RUN" ] && udisks --detach "${V_DEVICE%?}"
done
IFS=$V_OLD_IFS
