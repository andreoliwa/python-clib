#!/bin/bash

# First Desktop (0)
wmctrl -r 'Buddy List' -t 0 # Moves Pidgin to first desktop, if its window is open
wmctrl-set-position.sh sublime_text.sublime-text-2 0 0,0
wmctrl-set-position.sh gnome-terminal.Gnome-terminal 0 1400,100
wmctrl-set-position.sh chromium-browser.Chromium-browser 0 0,0
wmctrl-set-position.sh google-chrome.Google-chrome 0 0,0

# Second desktop (1)
wmctrl-set-position.sh Navigator.Firefox 1 1400,100
wmctrl-set-position.sh thunderbird 1 1400,0

# Third desktop (2)

# Fourth desktop (3)
wmctrl-set-position.sh update-manager.Update-manager 3 0,0
wmctrl-set-position.sh rhythmbox.Rhythmbox 3 1400,0
for V_NAUTILUS_WINDOW_ID in $(wmctrl -lx | grep nautilus | cut -d ' ' -f 1) ; do
	# Move all nautilus windows using their IDs
	wmctrl -i -r $V_NAUTILUS_WINDOW_ID -t 3
done
