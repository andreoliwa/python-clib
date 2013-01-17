#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Open files with Code Sniffer errors in Sublime Text.
Receives files from standard input.

Use it like this:
$ code-sniffer.sh -a directory1/ directory2/ directory3/ | $(basename $0)

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

cat | grep 'FILE:' | cut -b 7- | xargs subl
