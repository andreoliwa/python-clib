#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] <part of the movie's name>
Search a movie using parte of its name (wildcards are allowed).

-e  Search everywhere, not only the all movies directory
-h  Help"
	exit $1
}

V_SEARCH_EVERYWHERE=
while getopts "eh" OPTION ; do
	case $OPTION in
		e)	V_SEARCH_EVERYWHERE=1 ;;
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

V_ALL=All/
V_MAX_DEPTH=1
if [ -n "$V_SEARCH_EVERYWHERE" ] ; then
	V_ALL=
	V_MAX_DEPTH=2

	# Removes the first argument from the command line
	shift
fi

V_ARGS="$*"
V_QUERY="$(echo $V_ARGS | tr ' ' '*')"
find $G_MOVIES_HDD/Movies/$V_ALL -mindepth 1 -maxdepth $V_MAX_DEPTH -type d -iname "*${V_QUERY}*"
