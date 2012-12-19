#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Monitor system windows.

-n  Dry-run (doesn't write the database file)
-C  Create the SQLite database (if it doesn't exist)
-D  Open the SQLite database
-v  Verbose mode
-h  Help"
	exit $1
}

V_DRY_RUN=
V_CREATE_DATABASE=
V_OPEN_DATABASE=
V_VERBOSE=
while getopts "nCDvh" OPTION ; do
	case $OPTION in
	n)	V_DRY_RUN=1 ;;
	C)	V_CREATE_DATABASE=1 ;;
	D)	V_OPEN_DATABASE=1 ;;
	v)	V_VERBOSE=1 ;;
	h)	usage 1	;;
	?)	usage 2	;;
	esac
done

V_VLC='vlc.Vlc'
V_APPS="$V_VLC feh.feh google-chrome chromium-browser"

declare -A V_LAST_TITLE
declare -A V_LAST_DATE

V_GREP=
for V_APP in $V_APPS ; do
	V_GREP=$V_GREP" -e "$V_APP
	V_LAST_TITLE["$V_APP"]=
	V_LAST_DATE["$V_APP"]=
done

V_DATABASE=$HOME/.gtimelog/window-monitor.db
echo "Database file: $V_DATABASE"

if [ -n "$V_CREATE_DATABASE" ] ; then
	[ -n "$V_VERBOSE" ] && echo "Creating the SQLite database in $V_DATABASE"
	[ -f "$V_DATABASE" ] && echo -e "The SQLite database $V_DATABASE already exists. Please remove it manually first.\n" && usage 3

	echo "DROP TABLE IF EXISTS windows;
CREATE TABLE windows (window_id INTEGER PRIMARY KEY AUTOINCREMENT, start TIMESTAMP, end TIMESTAMP, class VARCHAR(100), title VARCHAR(1000));
" | sqlite3 $V_DATABASE

	# http://stackoverflow.com/questions/75675/how-do-i-dump-the-data-of-some-sqlite3-tables
	sqlite3 $V_DATABASE .dump
	exit 0
fi

if [ ! -f "$V_DATABASE" ] ; then
	echo -e "The SQLite database $V_DATABASE doesn't exist. Please create it with the option -C.\n"
	usage 2
fi

if [ -n "$V_OPEN_DATABASE" ] ; then
	sqlite3 $V_DATABASE
	exit 0
fi

echo 'Starting the window monitor...'
while true ; do

	sleep .2
	V_CURRENT_WINDOWS=$(wmctrl -l -x | grep $V_GREP | sed 's/ \+/ /g' | cut -d ' ' -f 3-)

	for V_APP in $V_APPS ; do
		V_TITLE=$(echo "$V_CURRENT_WINDOWS" | grep -e "^$V_APP" | sed "s/^${V_APP} ${HOSTNAME}\|N\/A //g")
		if [ "$V_APP" = "$V_VLC" ] ; then
			if [ "$V_TITLE" != ' VLC media player' ] ; then
				V_TITLE=$(lsof -F -c vlc | grep /media/ | sed "s#.\+${G_BACKUP_HDD}/system/##")
			fi
		fi

		if [ "${V_LAST_TITLE["$V_APP"]}" != "$V_TITLE" ] ; then
			V_NOW="$(date '+%Y-%m-%dT%H:%M:%S')"

			V_DIFF=0
			if [ -n "${V_LAST_DATE["$V_APP"]}" ] ; then
				V_SEC1=$(date -d ${V_LAST_DATE["$V_APP"]} +%s)
				V_SEC2=$(date -d $V_NOW +%s)
				V_DIFF=$(echo $V_SEC2 - $V_SEC1 | bc)
			fi

			if [ $V_DIFF -ge 2 ] && [ -n "${V_LAST_DATE["$V_APP"]}" ] ; then
				V_MESSAGE=${V_LAST_DATE["$V_APP"]}"\t$V_NOW\t$V_APP\t"${V_LAST_TITLE["$V_APP"]}
				echo -e $V_MESSAGE
				[ -z "$V_DRY_RUN" ] && echo "INSERT INTO windows (start, end, class, title)
VALUES ('${V_LAST_DATE["$V_APP"]}', '$V_NOW', '$V_APP', \"${V_LAST_TITLE["$V_APP"]}\");" | sqlite3 $V_DATABASE
			fi

			V_LAST_TITLE["$V_APP"]=$V_TITLE
			V_LAST_DATE["$V_APP"]=$V_NOW

			echo "Current window as of $V_NOW: $V_TITLE"
		fi
	done
done
