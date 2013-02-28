#!/bin/bash

# First Desktop (0)
wmctrl -r 'Buddy List' -t 0 # Moves Pidgin to first desktop, if its window is open
wmctrl-set-position.sh 0 0,0 sublime_text.sublime-text-2
wmctrl-set-position.sh 0 0,0 chromium-browser.Chromium-browser
wmctrl-set-position.sh 0 0,0 google-chrome.Google-chrome
for V_WINDOW_ID in $(wmctrl -lx | grep -i '\-terminal' | tr -s ' ' | cut -d ' ' -f 1) ; do
	# Move all terminal windows using their IDs
	wmctrl-set-position.sh 0 1400,100 $V_WINDOW_ID -i
done

# Second desktop (1)
wmctrl-set-position.sh 1 1400,100 Navigator.Firefox
wmctrl-set-position.sh 1 1400,0 thunderbird

# Third desktop (2)

# Fourth desktop (3)
wmctrl-set-position.sh 3 0,0 update-manager.Update-manager
wmctrl-set-position.sh 3 1400,0 rhythmbox.Rhythmbox
for V_WINDOW_ID in $(wmctrl -lx | grep -i -e nautilus -e thunar | cut -d ' ' -f 1) ; do
	# Move all file manager windows using their IDs
	wmctrl -i -r $V_WINDOW_ID -t 3
done
