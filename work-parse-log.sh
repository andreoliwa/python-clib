#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-h]
Parse do log de janela ativa.

OPTIONS
-h  Help"
	exit $1
}

V_LOGFILE=$HOME/.gtimelog/active-window.log

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)
			usage
			exit 1
			;;
		?)
			usage
			exit
			;;
	esac
done

V_OLD_IFS=$IFS
IFS='
'
for V_LINE in $(cat $V_LOGFILE) ; do
	V_DATE_TIME=$(echo $V_LINE | cut -d ' ' -f 1-2 | cut -b -16)
	V_APP=$(echo $V_LINE | cut -d ' ' -f 6)
	V_WINDOW_TITLE=$(echo $V_LINE | cut -d ' ' -f 8-)

	V_CATEGORY=$V_APP
	V_DESCRIPTION=$V_WINDOW_TITLE
	V_SLACK=

	case $V_APP in
	sublime_text.sublime-text-2)
		V_CATEGORY=Editor
		;;
	meld.Meld)
		V_CATEGORY=Diff
		;;
	gnome-terminal.Gnome-terminal)
		V_CATEGORY=Terminal
		;;
	Pidgin.Pidgin)
		V_CATEGORY=IM
		V_SLACK=' **'
		;;
	google-chrome.Google-chrome)
		if [[ "$V_WINDOW_TITLE" == *Snitch* ]] ; then
			V_CATEGORY=Snitch
		elif [[ "$V_WINDOW_TITLE" == *Contact* ]] ; then
			V_CATEGORY=Contact
		else
			V_CATEGORY=Browser
		fi
		;;
	Mail.Thunderbird)
		V_CATEGORY=E-mail
		;;
	esac

	if [[ "$V_CATEGORY" == *"."* ]] ; then
		V_CATEGORY=Outros
		V_DESCRIPTION=$V_APP
		V_SLACK=' **'
	fi

	if [ -n "$V_CATEGORY" ] ; then
		echo "${V_DATE_TIME}: ${V_CATEGORY}: ${V_DESCRIPTION}${V_SLACK}"
	fi
done
IFS=$V_OLD_IFS
