#!/bin/bash
usage() {
	echo "Usage: $(basename $0) directory1 [directory2...]
Searches directories looking for recently modified files, and tails them.

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

find $* -type f -daystart -mtime 0 | xargs tail -F
