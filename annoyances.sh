#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Log every time someone annoys and/or interrupts me.

Installation and use:

1) Run this script to create the SQLite database:
$ $0 -C

2) Configure your keyboard shortcut on Ubuntu:
System Settings / Keyboard / Shortcuts / Custom Shortcuts
Choose a key combination and fill in the full path of the script:
$0

3) Press the shortcut once to record your starting time.

4) Press the shortcut again to fill in the information about who interrupted you.

OPTIONS
-C  Create the SQLite database (if it doesn't exist)
-D  Open the SQLite database
-v  Verbose
-h  Help"
	exit $1
}

V_CREATE_DATABASE=
V_OPEN_DATABASE=
V_VERBOSE=
while getopts "CDvh" V_ARG ; do
	case $V_ARG in
	C)	V_CREATE_DATABASE=1 ;;
	D)	V_OPEN_DATABASE=1 ;;
	v)	V_VERBOSE=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_ANNOYANCES_DIR=~/.gtimelog/annoyances
mkdir -p $V_ANNOYANCES_DIR
V_CURRENT=$V_ANNOYANCES_DIR/current
V_PEOPLE_FILE=$V_ANNOYANCES_DIR/people

V_DATABASE=$V_ANNOYANCES_DIR/annoyances.db

if [ -n "$V_CREATE_DATABASE" ] ; then
	[ -n "$V_VERBOSE" ] && echo "Creating the SQLite database in $V_DATABASE"
	[ -f "$V_DATABASE" ] && echo -e "The SQLite database $V_DATABASE already exists. Please remove it manually first.\n" && usage 3

	# http://stackoverflow.com/questions/200309/sqlite-database-default-time-value-now
	echo "DROP TABLE IF EXISTS people;
CREATE TABLE people (person_id INTEGER PRIMARY KEY AUTOINCREMENT, name VARCHAR(100), counter INTEGER, added TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
DROP TABLE IF EXISTS annoyances;
CREATE TABLE annoyances (annoyance_id INTEGER PRIMARY KEY AUTOINCREMENT, person_id INTEGER, start TIMESTAMP, end TIMESTAMP, what VARCHAR(500));
" | sqlite3 $V_DATABASE

	# http://stackoverflow.com/questions/75675/how-do-i-dump-the-data-of-some-sqlite3-tables
	sqlite3 $V_DATABASE .dump
	exit 0
fi

if [ -n "$V_OPEN_DATABASE" ] ; then
	echo "People:"
	echo "SELECT * FROM people ORDER BY counter DESC, added;" | sqlite3 $V_DATABASE
	echo "Annoyances:"
	echo "SELECT * FROM annoyances;" | sqlite3 $V_DATABASE
	sqlite3 $V_DATABASE
	exit 0
fi

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

	zenity --error --text="Stopping music..."
}

end_annoyance() {
	[ -n "$V_VERBOSE" ] && echo "Stopping annoyance..."
	rm $V_CURRENT

	# Restart the music if it was playing before
	if [ -n "$(pidof rhythmbox)" ] ; then
		get_playing_song
		[ -n "$V_PLAYING_SONG" ] && rhythmbox-client --play
	fi

	# Join people together, separated by the pipe character
	V_PEOPLE="$(echo "SELECT name FROM people ORDER BY counter DESC, added;" | sqlite3 $V_DATABASE | tr "\n" '|' | sed 's/|\+$//')"

	V_LISTBOX="--list-values='$V_PEOPLE' --column-values=Who --add-list='Who interrupted me?'"
	V_INFO="$(eval "zenity --title='Stopping annoyance started on $V_START_TIME' --width=900 --forms $V_LISTBOX --add-entry='Add someone who is not on the list above:' --add-entry='What happened?' --text='Fill information about the interruption'")"
	[ -n "$V_VERBOSE" ] && echo "Information chosen in zenity window: $V_INFO"

	if [ -z "$V_INFO" ] ; then
		exit 3
	fi

	# http://stackoverflow.com/questions/10586153/bash-split-string-into-array
	IFS='|' read -a V_ARRAY <<< "$V_INFO"
	V_WHO_LIST="${V_ARRAY[0]}"
	V_WHO_ENTRY="${V_ARRAY[1]}"
	V_WHAT="${V_ARRAY[2]}"

	# The person might be in the list, or might be a new one
	V_WHO=
	if [ -n "$V_WHO_ENTRY" ] ; then
		V_WHO="$V_WHO_ENTRY"
		echo "INSERT INTO people (name, counter) VALUES ('$V_WHO', 0);" | sqlite3 $V_DATABASE
	else
		V_WHO="$V_WHO_LIST"
	fi

	# Find the person and increment the counter
	V_PERSON_ID=$(echo "SELECT person_id FROM people WHERE name = '$V_WHO';" | sqlite3 $V_DATABASE)
	echo "UPDATE people SET counter = counter + 1 WHERE person_id = '$V_PERSON_ID';" | sqlite3 $V_DATABASE

	# http://stackoverflow.com/questions/8903239/how-to-calculate-time-difference-in-bash-script
	[ -n "$V_VERBOSE" ] && echo "  Started on $V_START_TIME"
	V_END_TIME="$(date --rfc-3339=ns)"
	[ -n "$V_VERBOSE" ] && echo "  Ended on   $V_END_TIME"

	V_DIFF_SECONDS="$(time-diff.sh -s "$V_START_TIME" -e "$V_END_TIME")"
	[ -n "$V_VERBOSE" ] && echo "  Total annoyance time: $(($V_DIFF_SECONDS / 60)) minutes and $(($V_DIFF_SECONDS % 60)) seconds."

	V_LOG_MESSAGE="start=$V_START_TIME|end=$V_END_TIME|who=$V_INFO"
	[ -n "$V_VERBOSE" ] && echo $V_LOG_MESSAGE

	echo "INSERT INTO annoyances (person_id, start, end, what) VALUES ($V_PERSON_ID, '$V_START_TIME', '$V_END_TIME', '$V_WHAT');" | sqlite3 $V_DATABASE
}

V_START_TIME="$(cat $V_CURRENT 2>/dev/null)"
if [ -n "$V_START_TIME" ] ; then
	end_annoyance
else
	start_annoyance
fi
