#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] text
Change the case of text.

-c  Camel case
-s  Slug
-h  Help"
	exit $1
}

V_CAMEL_CASE=
V_SLUG=
while getopts "csh" V_ARG ; do
	case $V_ARG in
	c)	V_CAMEL_CASE=1 ;;
	s)	V_SLUG=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_CAMEL_CASE" ] && [ -z "$V_SLUG" ] ; then
	echo -e "Choose a case option: camel case (-c) or slug (-s).\n"
	usage 2
fi

V_TEXT=
while (( "$#" )) ; do
	# If it's not an option, we'll consider it text
	if [ "${1:0:1}" != '-' ] ; then
		V_TEXT="$V_TEXT $1"
	fi

	# Removes the first argument from the command line
	shift
done
V_TEXT="${V_TEXT:1}"

if [ -n "$V_SLUG" ]; then
	echo $V_TEXT | sed -e 's/\([A-Z][a-z0-9]\)/-\1/g' -e 's/^-//' | tr '[:upper:]' '[:lower:]' | tr --squeeze-repeats '_()#.,;:/?~^[]{} ' '-' | sed 'y/àáâãèéìíòóôõúçÀÁÂÃÈÉÌÍÒÓÔÕÚÇ/aaaaeeiiooooucaaaaeeiioooouc/'
fi

if [ -n "$V_CAMEL_CASE" ]; then
	V_OLD_IFS=$IFS
	IFS='_- '
	V_NEW_TEXT=
	for V_WORD in $V_TEXT ; do
		V_NEW_WORD=$(echo $V_WORD | tr '[:upper:]' '[:lower:]' | awk 'BEGIN{OFS=FS=""}{$1=toupper($1);print}')
		V_NEW_TEXT="$V_NEW_TEXT $V_NEW_WORD"
	done
	echo "${V_NEW_TEXT:1}" | tr --squeeze-repeats ' '
	IFS=$V_OLD_IFS
fi
