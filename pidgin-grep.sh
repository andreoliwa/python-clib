#!/bin/bash
ARGS="$*"
echo "Searching in Pidgin's zipped logfiles: $ARGS"
cd ~/Dropbox/Apps/PidginPortable/Data/settings/.purple/logs-tar
echo $PWD
for GZ_FILE in *.gz ; do
	tar -xOf $GZ_FILE | grep --color=auto -i $ARGS
done
