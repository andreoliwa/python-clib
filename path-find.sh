#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Find a file in the PATH environment variable.
If the file exists, shows the full file path; otherwise, shows nothing.

OPTIONS
-h   Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_FILE="$1"

V_OLD_IFS=$IFS
IFS=':'
for V_PATH_DIR in $PATH ; do
	if [ -f "$V_PATH_DIR/$V_FILE" ] ; then
		echo "$V_PATH_DIR/$V_FILE"
		break
	fi
done
IFS=$V_OLD_IFS
