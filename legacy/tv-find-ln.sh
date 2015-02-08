#!/bin/bash
TV_DIR=$G_MOVIES_HDD/TV

ARGS="$*"
VIDEO_FILENAME_PART=$1
WHERE=$2
if [ -z "$ARGS" -o -z "$VIDEO_FILENAME_PART" -o -z "$WHERE" ] ; then
	echo "Usage: tv-find-ln.sh <part of a video file name> <Both|Jaque|Wagner>"
	exit
fi

cd $TV_DIR
find ./All/ -iregex ".+$VIDEO_FILENAME_PART.+" -exec tv-ln.sh -r $WHERE -m '{}' \; | sort
