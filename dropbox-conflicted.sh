#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Show conflicted files in the Dropbox directory (and, optionally, remove them).

OPTIONS
-r  Remove the files
-h  Help"
	exit $1
}

V_REMOVE=
while getopts "rh" V_ARG ; do
	case $V_ARG in
	r)	V_REMOVE=" -exec rm -rvf '{}' \;" ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_CMD="find $HOME/Dropbox/ -iname '*conflicted copy*' $V_REMOVE"
eval $V_CMD
