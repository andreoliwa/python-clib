#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Move WhatsApp media to an external HDD, freeing cellphone space.

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ ! -d "$G_EXTERNAL_HDD" ] ; then
	echo -e "External HD is not connected: $G_EXTERNAL_HDD\n"
	usage 3
fi

if [ ! -d "$G_CELL_PHONE" ] ; then
	echo -e "Cell phone is not connected: $G_CELL_PHONE\n"
	usage 4
fi

V_IMAGES_DIR="$G_CELL_PHONE/WhatsApp/Media/WhatsApp Images"
if [ ! -d "$V_IMAGES_DIR" ] ; then
	echo -e "WhatsApp images directory doesn't exist: $V_IMAGES_DIR\n"
	usage 5
fi

V_BACKUP_DIR="$G_EXTERNAL_HDD/backup/whatsapp"

mkdir -p $V_BACKUP_DIR/images/
mv -v "$V_IMAGES_DIR"/* $V_BACKUP_DIR/images/
