#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [opcoes]
Monitora janelas do sistema.

OPCOES
-n   Dry-run
-t   Tail no log
-h   Ajuda
EOF
}

# Parse dos argumentos da linha de comando
V_DRY_RUN=
V_TAIL=
while getopts "nth" OPTION ; do
	case $OPTION in
	n)
		V_DRY_RUN=1
		;;
	t)
		V_TAIL=1
		;;
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit 1
		;;
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
if [ -n "$V_TAIL" ] ; then
	echo $V_LOGFILE
	tail -F $V_LOGFILE
	exit
fi

[ -z "$V_DRY_RUN" ] && echo >> $V_LOGFILE

echo 'Monitor de janelas...'
while true ; do

	sleep .2
	V_CURRENT_WINDOWS=$(wmctrl -l -x | grep $V_GREP | sed 's/ \+/ /g' | cut -d ' ' -f 3-)

	for V_APP in $V_APPS ; do
		V_TITLE=$(echo "$V_CURRENT_WINDOWS" | grep -e "^$V_APP" | sed "s/^${V_APP} ${HOSTNAME}\|N\/A //g")
		if [ "$V_APP" = "$V_VLC" ] ; then
			if [ "$V_TITLE" != ' VLC media player' ] ; then
				V_TITLE=$(lsof -F -c vlc | grep /media/ | sed 's@.\+/media/samsung-500gb/system/@@')
			fi
		fi
		V_NOW="$(date '+%Y-%m-%dT%H:%M:%S')"

		if [ "${V_LAST_TITLE["$V_APP"]}" != "$V_TITLE" ] ; then
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
		fi
	done
done
