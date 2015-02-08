#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Show conflicted files in the Dropbox directory (and, optionally, remove them).

OPTIONS
-k  Kill the files
-h  Help"
	exit $1
}

V_KILL=
while getopts "kh" V_ARG ; do
	case $V_ARG in
	k)	V_KILL=" -exec rm -rvf '{}' \;" ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_CMD="find $G_DROPBOX_DIR/ -iname '*conflicted copy*' $V_KILL"
eval $V_CMD
