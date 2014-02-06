#!/bin/bash

# Development
first_desktop() {
	V_DESKTOP=0
	wmctrl-set-position.sh $V_DESKTOP 0,0 sublime
	wmctrl-set-position.sh $V_DESKTOP 1400,0 chrom
	for V_WINDOW_ID in $(wmctrl -lx | grep -i '\-terminal' | tr -s ' ' | cut -d ' ' -f 1) ; do
		# Move all terminal windows using their IDs
		wmctrl-set-position.sh $V_DESKTOP 1400,100 $V_WINDOW_ID -i
	done

	# Pidgin: move and close the buddy list
	wmctrl -r 'Buddy List' -t $V_DESKTOP
	wmctrl -r 'Buddy List' -e 0,1020,30,250,950
	wmctrl -c 'Buddy List'

	# Pidgin: Move chat windows
	for V_PIDGIN_WINDOW_ID in $(wmctrl -lx | grep -i pidgin | tr -s ' ' | grep -v 'Buddy List' | cut -d ' ' -f 1) ; do
		wmctrl -i -r $V_PIDGIN_WINDOW_ID -t $V_DESKTOP
		wmctrl -i -r $V_PIDGIN_WINDOW_ID -e 0,1280,600,700,400
	done

	# Close Skype windows
	for V_SKYPE_WINDOW_ID in $(wmctrl -lx | grep ' skype.Skype ' | tr -s ' ' | cut -d ' ' -f 1) ; do
		wmctrl -i -c $V_SKYPE_WINDOW_ID
	done
}

# Text + E-mail
second_desktop() {
	V_DESKTOP=1
	wmctrl-set-position.sh $V_DESKTOP 1400,100 firefox
	wmctrl-set-position.sh $V_DESKTOP 1400,0 thunderbird
}

# Databases
third_desktop() {
	V_DESKTOP=2
	wmctrl-set-position.sh $V_DESKTOP 0,0 update-manager
	wmctrl-set-position.sh $V_DESKTOP 0,0 mysql-workbench
}

# Fun
fourth_desktop() {
	V_DESKTOP=3

	# Move all file manager windows using their IDs
	for V_WINDOW_ID in $(wmctrl -lx | grep -i -e nautilus -e thunar | cut -d ' ' -f 1) ; do
		wmctrl -i -r $V_WINDOW_ID -t $V_DESKTOP
	done
	wmctrl-set-position.sh $V_DESKTOP 1400,0 rhythmbox
}

first_desktop
second_desktop
third_desktop
fourth_desktop
