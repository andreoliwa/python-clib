#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Compare one photo directory with Shotwell, to check if any file is missing.

OPTIONS
-d  Picture directory to compare with Shotwell
-h  Help"
	exit $1
}

V_DIRECTORY=
while getopts "d:h" V_ARG ; do
	case $V_ARG in
	d)	V_DIRECTORY=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_DIRECTORY" ] ; then
	echo 'No directory specified'
	usage 3
fi

V_TMP_SHOTWELL=/tmp/shotwell.txt
echo "Finding files in Shotwell directory ($G_SHOTWELL_DIR)..."
find $G_SHOTWELL_DIR -type f -exec basename {} \; | sort -u >$V_TMP_SHOTWELL

V_TMP_PIX=/tmp/pix.txt
find $V_DIRECTORY -type f -exec basename {} \; | sort -u >$V_TMP_PIX

echo "Finding files in the supplied picture directory ($V_DIRECTORY)..."
meld $V_TMP_SHOTWELL $V_TMP_PIX
