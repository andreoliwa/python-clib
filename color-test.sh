#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Display some sample text using the configured color variables.

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

V_ALL_COLORS="$(env | grep -o '^COLOR_.\+=' | sed 's/=//')"
for V_COLOR_NAME in $V_ALL_COLORS ; do
	V_COLOR_CODE="echo -e \$${V_COLOR_NAME}"
	echo -e "$(eval $V_COLOR_CODE)Sample text using the color ${V_COLOR_NAME}${COLOR_NONE}"
done
