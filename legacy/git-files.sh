#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
Show files from a Git commit.

-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit
		;;
	esac
done

V_COMMIT=$1
git show $V_COMMIT --name-only --pretty="format:" | tail -n+2
