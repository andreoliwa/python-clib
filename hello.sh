#!/bin/bash

. ~/.bashrc

[ -z "$(pidof rescuetime)" -a "$(type -p rescuetime)" ] && rescuetime &

# Can't use "pidof gnome-do" because gnome-do is not the name of the executaable, so it doesn't have a PID
[ -z "$(ps aux | grep -v grep | grep gnome-do)" -a "$(type -p gnome-do)" ] && gnome-do &

echo "Hostname=$HOSTNAME"
echo "Work computer=$G_WORK_COMPUTER"
echo "Home computer=$G_HOME_COMPUTER"

if [ "$HOSTNAME" = "$G_WORK_COMPUTER" ] ; then
	# First workspace
	wmctrl -s 0
	gtimelog-lock-unlock.sh
	pidgin &
	sublime-text-2 &
	gnome-terminal --tab -e '/home/wagner/Dropbox/src/bash-utils/tmux-open.sh -s git' --tab -e '/home/wagner/Dropbox/src/bash-utils/tmux-open.sh -s mysql' &

	# Second workspace
	wmctrl -s 1

	thunderbird &
	rhythmbox &
	V_DOC_DIR='2work'
fi

if [ "$HOSTNAME" = "$G_HOME_COMPUTER" ] ; then
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
[ -n "$V_FIND" ] && echo "$V_FIND" | xargs xdg-open

# Show download folder if not empty (ignoring hidden files and dirs)
[ $(find $G_DOWNLOAD_DIR -type f -not -wholename '*/.*/*' | wc -l) -ne 0 ] && xdg-open $G_DOWNLOAD_DIR

if [ "$HOSTNAME" = "$G_WORK_COMPUTER" ] ; then
	# Returns to the first workspace
	wmctrl -s 0

	# Move windows to corresponding workspaces
	sleep 5
	wmctrl-move-windows.sh

	xdg-open $G_WORK_TIMECLOCK_URL &

	dropbox-shutdown.sh
else
	dropbox start
fi

V_HOME_OFFICE="$(git-home-office.sh -d)"
if [ -n "$V_HOME_OFFICE" ] ; then
	zenity --warning --no-wrap --text="<span foreground='red'><b>Hey there!</b></span>
There are pending remote work hours to send:
$(git-home-office.sh -td)" &
fi

V_SECONDS=10
echo "Sleeping $V_SECONDS seconds..."
sleep $V_SECONDS

# Show the workspaces indicator when we're not in a XFCE session
if [ -z "$(pidof xfce4-session)" ] ; then
	indicator-workspaces-restart.sh
fi
