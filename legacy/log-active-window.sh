#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-th]
Grava no log dados sobre a janela ativa (atual).
Execute sempre em background (&).

-t  Executa tail -f no log
-h  Help"
	exit $1
}

V_LOGFILE=$HOME/.gtimelog/active-window.log

while getopts "ht" V_ARG ; do
	case $V_ARG in
	t)
		V_COMMAND="tail -f $V_LOGFILE"
		echo $V_COMMAND
		$V_COMMAND
		exit
		;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ $(pidof -x $(basename $0) | wc -w) -gt 2 ] ; then
	echo 'Ja existe outra instancia deste script sendo executada:'
    ps aux | grep -v -e grep -e $$ | grep --color=auto $(basename $0)
	usage
    exit
fi

echo >> $V_LOGFILE
zenity --info --title='Log da janela ativa' --text="Iniciando gravação do log da janela ativa em $V_LOGFILE" &

V_LAST=
while true ; do
	# Lista os dados de todas as janelas ativas (wmctrl), e filtra pelo PID da janela atual (grep)
	V_CURRENT=$(wmctrl -lpx 2> /dev/null | grep "^0x[0-9a-f]\+ \+[0-9]\+ \+$(xdotool getactivewindow getwindowpid) \+")
	if [ -z "$V_CURRENT" ] ; then
		echo 'DEBUG - V_CURRENT vazia'
		wmctrl -lpx
		xdotool getactivewindow getwindowpid
	fi

	if [ "$V_CURRENT" != "$V_LAST" ] ; then
		V_LAST=$V_CURRENT
		V_MESSAGE="$(date '+%Y-%m-%d %H:%M:%S') $V_LAST"
		echo $V_MESSAGE >> $V_LOGFILE
	fi

	sleep .2
done
