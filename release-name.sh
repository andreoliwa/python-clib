#!/bin/bash
V_NEW_NAME=

# Get all command line arguments
OLD_IFS=$IFS
IFS=" ._"
for V_WORD in $* ; do
	V_WORD=${V_WORD,,}
	#echo $V_WORD

	# http://www.linuxjournal.com/content/bash-regular-expressions
	if [[ "$V_WORD" =~ ^[Ss][0-9][0-9][Ee][0-9][0-9]$ ]] ; then
		# Season and episode always in uppercase
		V_WORD="$(echo $V_WORD | tr '[:lower:]' '[:upper:]') "
	elif [ "$V_WORD" = 'srt' -o "$V_WORD" = 'avi' -o "$V_WORD" = 'mpg' -o "$V_WORD" = 'nfo' ] ; then
		# Extensions in lowercase
		V_WORD="$(echo $V_WORD | tr '[:upper:]' '[:lower:]')"
	elif [[ "$V_WORD" =~ ^dvdrip ]] ; then
		V_WORD=DVDRip${V_WORD:6}.
	elif [ "$V_WORD" = '-' ] ; then
		# Ignore some words
		V_WORD=
	else
		V_WORD=$(echo -n "${V_WORD^} ")
	fi

	V_NEW_NAME=${V_NEW_NAME}${V_WORD}
done
IFS=$OLD_IFS

# Spaces to points
V_NEW_NAME="$(echo $V_NEW_NAME | tr ' ' '.')"

echo $V_NEW_NAME