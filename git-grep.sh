#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Search the whole Git repository, looking for patterns.

OPTIONS
-e	Pattern to search. Can be used multiple times.
-l  Show files only
-h  Help"
	exit $1
}

V_ALL_PATTERNS=
V_FILES_ONLY=
while getopts "e:lh" V_ARG ; do
	case $V_ARG in
	e)	V_ALL_PATTERNS="$V_ALL_PATTERNS -e '$OPTARG'" ;;
	l)	V_FILES_ONLY=' -l' ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_CMD="time grep -R${V_FILES_ONLY} --color=auto --exclude-dir=.git --exclude-dir=mxzypkt.corp.folha.com.br $V_ALL_PATTERNS $G_WORK_SRC_DIR"
echo "$V_CMD"
eval "$V_CMD"
