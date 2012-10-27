#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] <parte do nome do filme>
Procura um filme usando parte do nome (wildcards sao permitidos).

  -h   Ajuda"
}

while getopts "h" OPTION ; do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit 1
		;;
	esac
done

V_ARGS="$*"
V_QUERY="$(echo $V_ARGS | tr ' ' '*')"
find $G_MOVIES_HDD/Movies/All/ -mindepth 1 -maxdepth 1 -type d -iname "*${V_QUERY}*"
