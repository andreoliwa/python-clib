#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Set the select MP3 files with special tags (intended for smart playlists).

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_FILES="$(zenity --file-selection --multiple --filename=*)"
V_PLAYLIST=@thrash

V_OLD_IFS=$IFS
IFS='|'
for V_FILE in $V_FILES ; do
	eyeD3 --to-v2.3 --text-frame TIT1:$V_PLAYLIST $V_FILE
done
IFS=$V_OLD_IFS

music-check.sh
