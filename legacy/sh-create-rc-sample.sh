#!/bin/bash
V_SAMPLE_FILE=$(dirname $0)/.clitoolkitrc.sample
V_RC_FILE=~/bin/.clitoolkitrc

usage() {
	echo "Usage: $(basename $0) [options]
Create a sample file called $V_SAMPLE_FILE from the $V_RC_FILE file.

OPTIONS
-h   Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

sed 's/\(export.\+=\).\+$/\1/' $V_RC_FILE > $V_SAMPLE_FILE
echo "Template file created: $(readlink -e $V_SAMPLE_FILE)"
cat $V_SAMPLE_FILE
