#!/bin/bash
DAYS=$1
[ -z "$DAYS" ] && DAYS=45

echo "Zipping Pidgin logs before $DAYS days"
cd $G_DROPBOX_DIR/Apps/PidginPortable/Data/settings/.purple
echo $PWD
mkdir -p ./logs-tar
find logs -mtime +$DAYS | xargs tar -cavf ./logs-tar/$(date --rfc-3339=seconds | cut -b 1-19 | tr ' :' '_-').tar.gz --remove-files

echo "Removing empty log dirs"
rmdir-empty.sh

echo "Pidgin 'logs' subdirectory still contains $(find logs -type f | wc -l) files"
