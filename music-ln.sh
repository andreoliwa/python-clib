#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Make a symbolic link to the music folders, restarting Rhythmbox.

OPTIONS
-l  Local hard drive
-e  External hard drive
-h  Help"
	exit $1
}

V_SOURCE=
while getopts "leh" V_ARG ; do
	case $V_ARG in
	l)	V_SOURCE="/home/music" ;;
	e)	V_SOURCE="$G_EXTERNAL_HDD/audio" ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

[ -z "$V_SOURCE" ] && usage 3

V_MUSIC_DIR=~/Music

pkill -9 rhythmbox

rm $V_MUSIC_DIR/in
ln -s $V_SOURCE/in/ $V_MUSIC_DIR/in

rm $V_MUSIC_DIR/unknown
ln -s $V_SOURCE/unknown/ $V_MUSIC_DIR/unknown

ls -l --color=auto $V_MUSIC_DIR

rhythmbox 1>/dev/null 2>&1 &

ps aux | grep rhythmbox
