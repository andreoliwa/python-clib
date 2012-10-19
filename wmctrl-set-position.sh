#!/bin/bash
TITLE=$1
DESKTOP=$2
COORD=$3
SIZE=1000,800

wmctrl -x -r $TITLE -t $DESKTOP
wmctrl -x -r $TITLE -b remove,maximized_vert,maximized_horz
wmctrl -x -r $TITLE -e 0,$COORD,$SIZE
wmctrl -x -r $TITLE -b add,maximized_vert,maximized_horz
