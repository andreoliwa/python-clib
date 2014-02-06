#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Synchronize music files between the hard drive and the mobile phone.

OPTIONS
-n  Dry-run
-h  Help"
	exit $1
}

V_DRY_RUN=
while getopts "nh" V_ARG ; do
	case $V_ARG in
	n)	V_DRY_RUN=-n ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_SOURCE_DIR="$G_EXTERNAL_HDD/audio/music/in/phone/"
V_DESTINATION_DIR='/media/MOTO DEFY/Music/phone/'
[ ! -d $V_SOURCE_DIR ] &&	echo "Source directory not found: $V_SOURCE_DIR" && exit
[ ! -d "$V_DESTINATION_DIR" ] && echo "Destination directory not found: $V_DESTINATION_DIR" && exit
rmdir-empty.sh $V_SOURCE_DIR
for PASS in {1..2} ; do
	echo "rsync $V_SOURCE_DIR -> $V_DESTINATION_DIR (pass $PASS)"
	rsync $V_DRY_RUN -hvuzr --links --delete-during --modify-window=2 --omit-dir-times --progress $V_SOURCE_DIR "$V_DESTINATION_DIR"
done
ntfs-check-filenames.sh $V_SOURCE_DIR

echo "Nao copia diretorio unknown ainda..."
exit

V_SOURCE_DIR='$G_EXTERNAL_HDD/audio/music/unknown/'
V_DESTINATION_DIR='/media/MOTO DEFY/Music/unknown/'
#@todo Nao fazer copy/paste
[ ! -d $V_SOURCE_DIR ] &&	echo "Source directory not found: $V_SOURCE_DIR" && exit
[ ! -d "$V_DESTINATION_DIR" ] && echo "Destination directory not found: $V_DESTINATION_DIR" && exit
rmdir-empty.sh $V_SOURCE_DIR
for PASS in {1..2} ; do
	echo "rsync $V_SOURCE_DIR -> $V_DESTINATION_DIR (pass $PASS)"
	rsync $V_DRY_RUN -hvuzr --links --delete-during --modify-window=2 --omit-dir-times --progress $V_SOURCE_DIR "$V_DESTINATION_DIR"
done
ntfs-check-filenames.sh $V_SOURCE_DIR
