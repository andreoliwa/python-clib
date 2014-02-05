#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] all terms to find
Find music in the external HDD.

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

V_FIND="$*"
V_CMD="find $G_EXTERNAL_HDD/audio/music -iwholename '*${V_FIND// /*}*' | sort"
echo "$V_CMD"
eval "$V_CMD"
