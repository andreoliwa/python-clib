#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Configure the workspace with everyday applications.

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

source ~/.bashrc
V_TMUX="$G_DROPBOX_DIR/src/python/clitoolkit/tmux-open.sh -s"
gnome-terminal --disable-factory --maximize --tab --title=git --command "$V_TMUX git" --tab --title=mysql --command "$V_TMUX mysql" --tab --title=vm217 --command "$V_TMUX vm217" --tab --command "ssh vm217" --tab &

# Returns to the first workspace and move windows to corresponding workspaces
sleep 1
wmctrl -s 0
wmctrl-move-windows.sh
