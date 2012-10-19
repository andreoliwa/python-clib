#!/bin/bash

# Moves Pidgin to first desktop
wmctrl -r 'Buddy List' -t 0

wmctrl-set-position.sh sublime_text.sublime-text-2 0 0,0
wmctrl-set-position.sh gnome-terminal.Gnome-terminal 0 1400,100
wmctrl-set-position.sh google-chrome.Google-chrome 1 0,0
wmctrl-set-position.sh Navigator.Firefox 1 1400,100
wmctrl-set-position.sh thunderbird 1 1400,0
wmctrl-set-position.sh rhythmbox.Rhythmbox 1 0,0
