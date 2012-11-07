#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
My last commit in this Git repo.

OPTIONS
-h   Help"
	exit $1
}

while getopts "h" OPTION ; do
	case $OPTION in
	h)	usage 1 ;;
	?)	usage 1	;;
	esac
done

git log -1 --author=$G_WORK_SVN_USERNAME
