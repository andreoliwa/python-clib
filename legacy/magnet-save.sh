#!/bin/bash
V_URL="$1"
V_MAGNET_LINK=$(wget -O - $V_URL | grep 'magnet:' | sed 's/.\+magnet/magnet/' | sort | uniq)

if [ -z "$V_MAGNET_LINK" ] ; then
	echo "This URL has no magnet links: $V_URL"
else
	echo "Magnet link found in URL: $V_MAGNET_LINK"
	V_MAGNET_FILE=~/.config/deluge/all-torrents/$(basename $V_URL).magnet
	echo $V_MAGNET_LINK > $V_MAGNET_FILE
	echo "Magnet file saved: $V_MAGNET_FILE"

	cp $V_MAGNET_FILE $G_DROPBOX_DIR/torrent
	echo "Magnet file copied to $G_DROPBOX_DIR/torrent"
fi
