#!/bin/bash
V_DESKTOP=$1
V_COORD=$2
V_TITLE=$3
V_EXTRA=$4
V_SIZE=$5
[ -z "$V_SIZE" ] && V_SIZE=1000,800

wmctrl -x $V_EXTRA -r $V_TITLE -t $V_DESKTOP
wmctrl -x $V_EXTRA -r $V_TITLE -b remove,maximized_vert,maximized_horz
wmctrl -x $V_EXTRA -r $V_TITLE -e 0,$V_COORD,$V_SIZE
wmctrl -x $V_EXTRA -r $V_TITLE -b add,maximized_vert,maximized_horz
