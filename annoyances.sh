#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Log every time someone annoys and/or interrupts me.

OPTIONS
-v  Verbose mode
-h  Help"
	exit $1
}

V_VERBOSE=
while getopts "vh" V_ARG ; do
	case $V_ARG in
	v)	V_VERBOSE=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_ANNOYANCES_DIR=/home/wagner/.gtimelog/annoyances
mkdir -p $V_ANNOYANCES_DIR
V_CURRENT=$V_ANNOYANCES_DIR/current

get_playing_song() {
	V_PLAYING_SONG="$(rhythmbox-client --print-playing)"
	[ "$V_PLAYING_SONG" == ' - ' ] && V_PLAYING_SONG=
	[ -n "$V_VERBOSE" ] && echo "Playing song: $V_PLAYING_SONG"
}

start_annoyance() {
	V_START_TIME="$(date --rfc-3339=ns)"
	[ -n "$V_VERBOSE" ] && echo "Starting annoyance at $V_START_TIME"
	echo $V_START_TIME > $V_CURRENT

	# Stop the music if it's playing
	if [ -n "$(pidof rhythmbox)" ] ; then
		get_playing_song
		rhythmbox-client --pause
	fi
}

end_annoyance() {
	[ -n "$V_VERBOSE" ] && echo "Stopping annoyance..."
	rm $V_CURRENT

	# Restart the music if it was playing before
	if [ -n "$(pidof rhythmbox)" ] ; then
		get_playing_song
		[ -n "$V_PLAYING_SONG" ] && rhythmbox-client --play
	fi

	V_INFO="$(zenity --title="Stopping annoyance started on $V_START_TIME" --width=700 --forms --list-values='Webysther|Carlos|Amemiya|Marcelo|Ari|Pincelso|Juliana|Alisson' --column-values=Who --add-list=Who --add-entry=Who --add-entry=What --text='Annoyance info')"
	[ -n "$V_VERBOSE" ] && echo "Information: $V_INFO"

	# http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script
	[ -n "$V_VERBOSE" ] && echo "  Started on $V_START_TIME"
	V_END_TIME="$(date --rfc-3339=ns)"
	[ -n "$V_VERBOSE" ] && echo "  Ended on   $V_END_TIME"

	V_DIFF_SECONDS="$(time-diff.sh -s "$V_START_TIME" -e "$V_END_TIME")"
	[ -n "$V_VERBOSE" ] && echo "  Total annoyance time: $(($V_DIFF_SECONDS / 60)) minutes and $(($V_DIFF_SECONDS % 60)) seconds."
}

V_START_TIME="$(cat $V_CURRENT 2>/dev/null)"
if [ -n "$V_START_TIME" ] ; then
	end_annoyance
else
	start_annoyance
fi
#/home/wagner/.gtimelog/annoyance.log
