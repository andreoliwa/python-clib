#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
My last commit in this Git repo.

OPTIONS
-h   Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)	usage 1 ;;
	?)	usage 1	;;
	esac
done

git log -1 --author=$G_WORK_SVN_USERNAME
