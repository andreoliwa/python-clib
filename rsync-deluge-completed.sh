#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Rsyncs complete Deluge downloads to an external HDD.

OPTIONS
-o   Open directory in Nautilus after rsync is over
-h   Help"
	exit $1
}

V_OPEN_IN_NAUTILUS=
while getopts "oh" V_ARG ; do
	case $V_ARG in
		o)	V_OPEN_IN_NAUTILUS=1 ;;
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_DELUGE=$HOME/.config/deluge/completed-downloads
V_HD=$G_EXTERNAL_HDD

if [ ! -d "$V_HD" ] ; then
	echo "External HD not found: $V_HD"
	usage 2
fi

if [ ! -d "$V_DELUGE" ] ; then
	echo "Deluge directory not found: $V_DELUGE"
	usage 3
fi

echo "Syncing..."
rsync -havuz --progress --modify-window=2 $V_DELUGE $V_HD/

echo "Checking again..."
rsync -havuz --progress --modify-window=2 $V_DELUGE $V_HD/

if [ -n "$V_OPEN_IN_NAUTILUS" ] ; then
	echo "Opening $V_HD in nautilus"
	nautilus $V_HD
else
	echo -e "\nShowing Deluge files in $V_DELUGE"
	ls -l --color=auto $V_DELUGE

	echo -e "\nShowing external HDD files in $V_HD/$(basename $V_DELUGE)"
	ls -l --color=auto "$V_HD/$(basename $V_DELUGE)"
fi
