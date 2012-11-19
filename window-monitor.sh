#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Monitors system windows.

-n  Dry-run (doesn't write the log file)
-t  Tail log
-e  Edit log
-h  Help"
	exit $1
}

V_DRY_RUN=
V_TAIL=
V_EDIT=
while getopts "nteh" OPTION ; do
	case $OPTION in
	n)	V_DRY_RUN=1 ;;
	t)	V_TAIL=1 ;;
	e)	V_EDIT=1 ;;
	h)	usage 1	;;
	?)	usage 1	;;
	esac
done

V_VLC='vlc.Vlc'
V_APPS="$V_VLC feh.feh google-chrome"
#V_APPS="sublime_text.sublime-text-2 google-chrome.Google-chrome"

declare -A V_LAST_TITLE
declare -A V_LAST_DATE

V_GREP=
for V_APP in $V_APPS ; do
	V_GREP=$V_GREP" -e "$V_APP
	V_LAST_TITLE["$V_APP"]=
	V_LAST_DATE["$V_APP"]=
done

V_LOGFILE=$HOME/.gtimelog/$(basename $0).log
if [ -n "$V_EDIT" ] ; then
	subl $V_LOGFILE
	exit 0
fi
if [ -n "$V_TAIL" ] ; then
	echo $V_LOGFILE
	tail -F $V_LOGFILE
	exit 0
fi

[ -z "$V_DRY_RUN" ] && echo >> $V_LOGFILE

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
				[ -z "$V_DRY_RUN" ] && echo -e $V_MESSAGE >> $V_LOGFILE
			fi

			V_LAST_TITLE["$V_APP"]=$V_TITLE
			V_LAST_DATE["$V_APP"]=$V_NOW

			echo "Current window as of $V_NOW: $V_TITLE"
		fi
	done
done
