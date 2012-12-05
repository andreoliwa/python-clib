#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Change a git-svn-id to a SVN link in data received from stdin.

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

cat | sed "s#^.\+git-svn-id.\+/svn/\([a-z_]\+\)@\([0-9]\+\).\+\$#${G_WSVN_URL}/revision.php?repname=\1\&rev=\2#"
