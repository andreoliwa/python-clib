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
gnome-terminal --disable-factory --maximize --tab --title=git --command "$G_DROPBOX_DIR/src/bash-utils/tmux-open.sh -s git" --tab --title=mysql --command "$G_DROPBOX_DIR/src/bash-utils/tmux-open.sh -s mysql" --tab --title=vm206 --command "$G_DROPBOX_DIR/src/bash-utils/tmux-open.sh -s vm206" --tab --command "ssh vm206" --tab &

# Returns to the first workspace and move windows to corresponding workspaces
sleep 1
wmctrl -s 0
wmctrl-move-windows.sh
