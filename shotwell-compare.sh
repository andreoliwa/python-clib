#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Compare one photo directory with Shotwell, to check if any file is missing.

OPTIONS
-d  Picture directory to compare with Shotwell. If this option is not informed, assumes the current dir.
-h  Help"
	exit $1
}

V_DIRECTORY=
while getopts "d:h" V_ARG ; do
	case $V_ARG in
	d)	V_DIRECTORY="$(readlink -f $OPTARG)" ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_DIRECTORY" ] ; then
	V_DIRECTORY="$PWD"
fi

V_TMP_SHOTWELL=/tmp/shotwell.txt
echo "Finding files in Shotwell directory ($G_SHOTWELL_DIR)..."
find $G_SHOTWELL_DIR -type f -exec basename {} \; | sort -u >$V_TMP_SHOTWELL

V_TMP_PIX=/tmp/pix.txt
find "$V_DIRECTORY" -type f -exec basename {} \; | sort -u >$V_TMP_PIX

echo "Finding files in the supplied picture directory ($V_DIRECTORY)..."
#meld $V_TMP_SHOTWELL $V_TMP_PIX

V_DIFF="$(diff $V_TMP_SHOTWELL $V_TMP_PIX | grep '^>' | sed 's/^> //')"
if [ -n "$V_DIFF" ] ; then
	echo -en $COLOR_LIGHT_RED
	echo "MISSING FILES! These files were not found in the Shotwell directory:"
	echo -en $COLOR_NONE
	echo "$V_DIFF"
else
	echo -en $COLOR_GREEN
	echo "Ok. All files are identical; you can remove the pictures from $V_DIRECTORY."
fi
