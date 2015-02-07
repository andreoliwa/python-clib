#!/bin/bash

V_ID3_INFO=$1
[ -z $V_ID3_INFO ] && V_ID3_INFO=TIT1
#[ -z $V_ID3_INFO || ( $V_ID3_INFO == "quality" ) ] && V_ID3_INFO=TIT1

echo "Showing the ${V_ID3_INFO} tag of all MP3 files in this directory:"
find -iname '*.mp3' -exec id3v2 --list '{}' \; | grep -i -e $V_ID3_INFO -e filename -e 'No ID3' | sort | uniq
