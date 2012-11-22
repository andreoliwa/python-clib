#!/bin/bash
V_SAMPLE_FILE=my-variables.sample
V_MY_VARIABLES_FILE=~/bin/my-variables

usage() {
	echo "Usage: $(basename $0) [options]
Create a sample file called $V_SAMPLE_FILE from the $V_MY_VARIABLES_FILE file.

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

sed 's/\(export.\+=\).\+$/\1/' $V_MY_VARIABLES_FILE > $V_SAMPLE_FILE
echo "Template file created: $(readlink -e $V_SAMPLE_FILE)"
cat $V_SAMPLE_FILE
