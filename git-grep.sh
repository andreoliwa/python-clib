#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Search the whole Git repository, looking for patterns.

OPTIONS
-e	Pattern to search. Can be used multiple times.
-h  Help"
	exit $1
}

V_ALL_PATTERNS=
while getopts "e:h" V_ARG ; do
	case $V_ARG in
	e)	V_ALL_PATTERNS="$V_ALL_PATTERNS -e '$OPTARG'" ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_CMD="time grep -R --color=auto --exclude-dir=.git --exclude-dir=mxzypkt.corp.folha.com.br $V_ALL_PATTERNS $G_WORK_SRC_DIR"
echo "$V_CMD"
eval "$V_CMD"
