#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Decode HTML characters read from stdin.

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

V_HTML="$(cat)"

# http://stackoverflow.com/questions/6250698/shell-script-to-urldecode-file-contents
echo -e "$(echo "$V_HTML" | sed 'y/+/ /; s/%/\\x/g')"
