#!/bin/bash

QUALITY=$1
FILES=$2

if [ -z $QUALITY ] ; then
	QUALITY=$(zenity --list --column=Qualidade --text='Escolha uma:' 1-masterpiece 2-excellent 3-very-good 4-good 5-interesting 6-funny 6-jaque 9-boring 9-crap 9-ok)
fi

if [ -z $QUALITY ] ; then
	echo 'beet-set-grouping.sh <quality> <files>'
	echo 'quality: 1-masterpiece'
	echo '         2-excellent'
	echo '         3-very-good'
	echo '         4-good'
	echo '         5-interesting'
	echo '         6-funny'
	echo '         6-jaque'
	echo '         9-boring'
	echo '         9-crap'
	echo '         9-ok'
else
	if [ -z "$FILES" ] ; then
		id3v2 -C *.mp3
		id3v2 --TIT1 $QUALITY *.mp3
	else
		id3v2 -C "$FILES"
		id3v2 --TIT1 $QUALITY "$FILES"
	fi
	echo
	music-get-grouping.sh
fi
