#!/bin/bash -x
source ~/.bashrc

echo "Hostname=$HOSTNAME"
echo "Work computer=$G_WORK_COMPUTER"
echo "Home computer=$G_HOME_COMPUTER"

# Can't use "pidof gnome-do" because "gnome-do" is not the executable's name, so it doesn't have a PID
[ -z "$(ps aux | grep -v grep | grep gnome-do)" -a "$(type -p gnome-do)" ] && gnome-do &

[ -z "$(ps aux | grep -v grep | grep indicator-multiload)" -a "$(type -p indicator-multiload)" ] && indicator-multiload --trayicon &

[ -z "$(pidof imwheel)" -a "$(type -p imwheel)" ] && imwheel

[ -z "$(pidof rescuetime)" -a "$(type -p rescuetime)" ] && rescuetime &

monitors.sh

if [ "$HOSTNAME" = "$G_WORK_COMPUTER" ] ; then
	# First workspace
	wmctrl -s 0
	pidgin &
	subl &

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
V_OLD_IFS=$IFS
IFS='
'
V_FIND=$(find $HOME -maxdepth 4 -type d -not -empty -and \( -name 2both -or -name $V_DOC_DIR -or -wholename '*deluge*downloads' \))
if [ -n "$V_FIND" ]; then
	for V_ONE_DIR in $V_FIND; do
		xdg-open $V_ONE_DIR
	done
fi
IFS=$V_OLD_IFS

# Show download folder if not empty (ignoring hidden files and dirs)
[ $(find $G_DOWNLOAD_DIR -type f -not -wholename '*/.*/*' | wc -l) -ne 0 ] && xdg-open $G_DOWNLOAD_DIR

if [ "$HOSTNAME" = "$G_WORK_COMPUTER" ] ; then
	dropbox-shutdown.sh
else
	for V_WINDOW_ID in $(wmctrl -lx | grep -i '\-terminal' | tr -s ' ' | cut -d ' ' -f 1) ; do
		# Move all terminal windows using their IDs
		wmctrl-set-position.sh 0 1400,100 $V_WINDOW_ID -i
	done

	dropbox start
fi

V_HOME_OFFICE="$(git-home-office.sh -d)"
if [ -n "$V_HOME_OFFICE" ] ; then
	zenity --warning --no-wrap --text="<span foreground='red'><b>Hey there!</b></span>
There are pending remote work hours to send:
$(git-home-office.sh -td)" &
fi

# Show the workspaces indicator when we're not in a XFCE session
if [ -z "$(pidof xfce4-session)" ] ; then
	V_SECONDS=10
	echo "Sleeping $V_SECONDS seconds..."
	sleep $V_SECONDS

	indicator-workspaces-restart.sh
fi

if [ "$HOSTNAME" = "$G_WORK_COMPUTER" ] ; then
	gnome-terminal -x ssh vm206 &
else
	skype &
fi

# I don't know why, but sometimes this script appears multiple times in the process list.
# So, allow me to kill myself.
pkill $(basename $0)
