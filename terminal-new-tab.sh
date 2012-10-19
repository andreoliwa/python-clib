#!/bin/bash
# http://stackoverflow.com/questions/1188959/open-a-new-tab-in-gnome-terminal-using-command-line
V_WINDOW_ID=$(xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)"| awk '{print $5}')
xdotool windowfocus $V_WINDOW_ID
xdotool key ctrl+shift+t
wmctrl -i -a $V_WINDOW_ID

# Wait a little and the type all the arguments in the new tab
#sleep 1
#xdotool windowactivate $V_WINDOW_ID sleep 1 exec $*
