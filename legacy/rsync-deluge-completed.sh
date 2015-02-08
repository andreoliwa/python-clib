#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Copy completed Deluge downloads to an external HDD, using rsync.

OPTIONS
-o  Open directory in file manager after rsync is over
-h  Help"
	exit $1
}

V_OPEN_IN_FILE_MANAGER=
while getopts "oh" V_ARG ; do
	case $V_ARG in
		o)	V_OPEN_IN_FILE_MANAGER=1 ;;
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_DELUGE_DIR=$G_EXTERNAL_HDD/deluge
V_DEST_DIR=$V_DELUGE_DIR/ready-to-organize

V_OLD_IFS=$IFS
IFS='
'
for V_SOURCE_FILE in $(find $V_DELUGE_DIR/ -type f -not \( -name .keep -or -wholename *$V_DEST_DIR* -or -wholename */.incomplete* -or -wholename */.kill* \)); do
	V_DEST_FILE="${V_SOURCE_FILE/$V_DELUGE_DIR/$V_DEST_DIR}"
	mkdir -p "$(dirname "$V_DEST_FILE")"

	cp -uv "$V_SOURCE_FILE" "$V_DEST_FILE"
done
IFS=$V_OLD_IFS

rmdir-empty.sh $V_DELUGE_DIR
exit





V_DELUGE=$HOME/.config/deluge/completed-downloads
V_HD=$G_EXTERNAL_HDD/backup

if [ ! -d "$V_HD" ] ; then
	echo "External HD not found: $V_HD"
	usage 2
fi

if [ ! -d "$V_DELUGE" ] ; then
	echo "Deluge directory not found: $V_DELUGE"
	usage 3
fi

echo "Syncing..."
rsync -havuz --progress --modify-window=2 $V_DELUGE $V_HD/

echo "Checking again..."
rsync -havuz --progress --modify-window=2 $V_DELUGE $V_HD/

if [ -n "$V_OPEN_IN_FILE_MANAGER" ] ; then
	echo "Opening $V_HD in file manager"
	xdg-open $V_HD
else
	echo -e "\nShowing Deluge files in $V_DELUGE"
	ls -l --color=auto $V_DELUGE

	echo -e "\nShowing external HDD files in $V_HD/$(basename $V_DELUGE)"
	ls -l --color=auto "$V_HD/$(basename $V_DELUGE)"
fi
