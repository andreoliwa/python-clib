#!/bin/bash

[ -z "$(pidof rescuetime)" ] && rescuetime &

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	# First workspace
	wmctrl -s 0
	gtimelog-lock-unlock.sh
	pidgin &
	sublime-text-2 &
	gnome-terminal --tab --working-directory="$G_WORK_SRC_DIR/dev_bin" --tab --working-directory="$G_WORK_SRC_DIR/dev_htdocs" &

	# Second workspace
	wmctrl -s 1

	thunderbird &
	rhythmbox &
	V_DOC_DIR='2work'
fi

if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
	V_DOC_DIR='2home'
fi

# Warn about files in the HOME directory
V_FIND="$(find $HOME -maxdepth 1 -type f -not -name '.*')"
if [ -n "$V_FIND" ] ; then
	echo "$V_FIND"
	zenity --warning --no-wrap --text="There are some files in the HOME directory:

$V_FIND" &
fi

# Show files in download dirs
V_FIND=$(find $HOME -type d -not -empty -and \( -name 2both -or -name $V_DOC_DIR -or -wholename '*deluge*downloads' \))
[ -n "$V_FIND" ] && echo "$V_FIND" | xargs nautilus

# Show download folder if not empty
[ $(find $G_DOWNLOAD_DIR -type f | wc -l) -ne 0 ] && nautilus $G_DOWNLOAD_DIR

indicator-workspaces-restart.sh

if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	# Returns to the first workspace
	wmctrl -s 0

	# Move windows to corresponding workspaces
	sleep 5
	wmctrl-move-windows.sh

	google-chrome http://ponto.cpndin.com.br/ &

	work-log-active-window.sh &
fi

V_HOME_OFFICE="$(git-home-office.sh -d)"
if [ -n "$V_HOME_OFFICE" ] ; then
	zenity --warning --no-wrap --text="<span foreground='red'><b>Hey there!</b></span>
There are pending remote work hours to send:
$(git-home-office.sh -td)" &
fi
