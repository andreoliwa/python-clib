#!/bin/bash
DELUGE=$HOME/.config/deluge/completed-downloads
HD=$G_EXTERNAL_HDD/

[ ! -d $HD ] && echo "External HD not found: $HD"
[ ! -d $DELUGE ] && echo "Deluge directory not found: $DELUGE"
if [ -d $HD -a -d $DELUGE ] ; then
	echo "Syncing..."
	rsync -havuz --progress --modify-window=2 $DELUGE $HD
	echo "Checking again..."
	rsync -havuz --progress --modify-window=2 $DELUGE $HD
	echo "Opening $HD in nautilus"
	nautilus $HD
fi
