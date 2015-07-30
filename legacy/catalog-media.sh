#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Catalog and list files in external drives.

OPTIONS
-l  List catalogs
-o  Open catalogs
-h  Help"
	exit $1
}

V_LIST=
V_OPEN=
while getopts "loh" V_ARG ; do
	case $V_ARG in
	l)	V_LIST=1 ;;
	o)	V_OPEN=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_CATALOG_DIR=$G_DROPBOX_DIR/linux

if [ -n "$V_OPEN" ]; then
	subl $V_CATALOG_DIR/catalog-media*
	exit
fi

if [ -z "$V_LIST" ]; then
	cd /media
	for V_MEDIUM in $(find /media -maxdepth 2 -name 'red*' -or -name 'black*' 2>/dev/null) ; do
		V_FILE=$V_CATALOG_DIR/catalog-media-$(basename $V_MEDIUM).txt
		echo "Cataloging $V_MEDIUM into $V_FILE"
		ls -clAhRF --author $V_MEDIUM/ > $V_FILE
	done
fi

ls -lt $V_CATALOG_DIR/catalog-media*
