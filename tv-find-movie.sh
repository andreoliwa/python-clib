#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] <part of the movie's name>
Search a movie using parte of its name (wildcards are allowed).

-m  Search only the main movies directory
-k  Kill the movies
-h  Help"
	exit $1
}

V_SEARCH_MAIN=
V_KILL=
while getopts "mkh" V_ARG ; do
	case $V_ARG in
		m)	V_SEARCH_MAIN=1 ;;
		k)	V_KILL=1 ;;
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

if [ -n "$V_SEARCH_MAIN" ] ; then
	V_ALL=All/
	V_MAX_DEPTH=1
else
	V_ALL=
	V_MAX_DEPTH=2
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

V_QUERY="*$(echo $V_TEXT | tr ' ' '*')*"

V_FIND="find $G_MOVIES_HDD/Movies/$V_ALL -mindepth 1 -maxdepth $V_MAX_DEPTH -type d -iname \"${V_QUERY}\""
if [ -n "$V_KILL" ] ; then
	V_FIND="${V_FIND} -exec rm -rvf '{}' \;"
fi

eval "$V_FIND"