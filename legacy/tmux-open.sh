#!/bin/bash
V_RC_FILE="~/.tmuxopenrc"

usage() {
	echo -e "Usage: $(basename $0) [options]
Open a session by its name.\n"
	echo "Available session names ($V_RC_FILE):"
	cat $V_RC_FILE | grep -o '^tmux_session_[a-zA-Z0-9]\+' | sed 's/tmux_session_//'
	echo -e "\nOPTIONS
-s  Session name
-k  Kill session
-r  Restart session
-h  Help"
	exit $1
}

source $V_RC_FILE

V_SESSION=
V_KILL=
V_RESTART=
while getopts "s:krh" V_ARG ; do
	case $V_ARG in
	s)	V_SESSION=$OPTARG ;;
	k)	V_KILL=1 ;;
	r)	V_RESTART=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_SESSION" ] ; then
	echo -e "Please supply a session name!"
	usage 3
fi

tmux has-session -t "$V_SESSION"

if [ $? -eq 0 ] ; then
	if [ -n "$V_KILL" -o -n "$V_RESTART" ] ; then
		echo "Killing session $V_SESSION"
		tmux kill-session -t $V_SESSION
		sleep 2
		if [ -z "$V_RESTART" ] ; then
			exit
		fi

		echo "Restarting session $V_SESSION"
	else
		echo "Session $V_SESSION already exists, attaching to the terminal"
		tmux attach-session -d -t $V_SESSION
		exit
	fi
else
	if [ -n "$V_KILL" -o -n "$V_RESTART" ] ; then
		echo "Session $V_SESSION does not exist"
		exit
	else
		echo "Creating session $V_SESSION"
	fi
fi

# Create session and attach it to a terminal window
V_FUNCTION="tmux_session_$V_SESSION"
$V_FUNCTION "$V_SESSION"

# Set window title
tmux set -t $V_SESSION set-titles on
tmux set -t $V_SESSION set-titles-string $V_SESSION

tmux attach-session -d -t $V_SESSION
