#!/bin/bash
V_FILES=*.mp3
V_TMP_FILE1=/tmp/music-check1.txt
V_TMP_FILE2=/tmp/music-check2.txt

[ -f $V_TMP_FILE1 ] && rm $V_TMP_FILE1
[ -f $V_TMP_FILE2 ] && rm $V_TMP_FILE2
for V_FILE in $V_FILES ; do
	id3 -l -R "${PWD}/${V_FILE}" >> $V_TMP_FILE1
	id3v2 -l "${PWD}/${V_FILE}" >> $V_TMP_FILE2
done
echo ">>>>> ID3v1"
cat $V_TMP_FILE1 | sort | uniq | grep --colour=auto -e Artist -e Album -e 'Year:' -e Genre

echo
echo ">>>>> ID3v2"
cat $V_TMP_FILE2 | sort | uniq | grep --colour=auto -e TALB -e TCON -e TIT1 -e TPE1 -e TPE2 -e TYER -e 'No ID3' -e Album -e 'Year:' -e Genre
