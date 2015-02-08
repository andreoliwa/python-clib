#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Set the BPM in the files, used to classify them in Beets.

OPTIONS
-n  Dry-run
-b  Set the BPM
-r  Remove the BPM
-f  Files to be set. Defaults to all files if not used. Can be used multiple times
-l  List available BPMs
-h  Help"
	exit $1
}

V_DRY_RUN=
V_BPM=
V_REMOVE=
V_FILES=
V_LIST=
while getopts "nb:rf:lh" V_ARG ; do
	case $V_ARG in
	n)	V_DRY_RUN=1 ;;
	b)	V_BPM=$OPTARG ;;
	r)	V_REMOVE=1 ;;
	f)	V_FILES="$V_FILES '$OPTARG'" ;;
	l)	V_LIST=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

[ -z "$V_FILES" ] && V_FILES=.

V_BPM_LIST='masterpiece 1
excellent   2
very-good   3
good        4
interesting 5
funny       6
ok          7
boring      8
crap        9'

V_CMD=
if [ -n "$V_LIST" ] ; then
	echo -e "$V_BPM_LIST"
	exit
elif [ -n "$V_BPM" ] ; then
	V_CMD="eyeD3 --to-v2.3 --bpm $V_BPM $V_FILES"
elif [ -n "$V_REMOVE" ] ; then
	V_CMD="eyeD3 --to-v2.3 --remove-frame TBPM $V_FILES"
fi

if [ -z "$V_CMD" ] ; then
	# I think something happened to zenity in Ubuntu 13.10. The return value is now repeated. Before: "1" Now: "1|1"
	V_BPM=$(zenity --print-column=2 --separator=# --list --height=400 --column=Description --column=BPM --text='Pick one:' $V_BPM_LIST | sed 's/#.\+//')
	if [ -z "$V_BPM" ] ; then
		usage
	fi

	V_CMD="eyeD3 --to-v2.3 --bpm $V_BPM $V_FILES"
fi

echo "$V_CMD"
if [ -z "$V_DRY_RUN" ] ; then
	eval "$V_CMD"
	music-check.sh
fi
