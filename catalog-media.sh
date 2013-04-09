#!/bin/bash
V_CATALOG_DIR=$G_DROPBOX_DIR/linux
cd /media
for V_MEDIUM in $(find /media -maxdepth 2 -name red* -or -name '*samsung*' 2>/dev/null) ; do
	V_FILE=$V_CATALOG_DIR/catalog-media-$(basename $V_MEDIUM).txt
	echo "Cataloging $V_MEDIUM into $V_FILE"
	ls -clAhRF --author $V_MEDIUM/ > $V_FILE
done
ls -lt $V_CATALOG_DIR/catalog-media*
