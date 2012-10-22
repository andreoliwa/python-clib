#!/bin/bash
CATALOG_DIR=$HOME/Dropbox/linux
cd /media
for MEDIUM in $(find /media -maxdepth 1 -name red* -or -name '*samsung*' | cut -b 8-) ; do
	echo "Cataloging $MEDIUM"
	ls -clAhRF --author /media/$MEDIUM/ > $CATALOG_DIR/catalog-media-$MEDIUM.txt
done
ls -lt $CATALOG_DIR/catalog-media*
