#!/bin/bash
. ~/bin/my-variables

if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
	echo 'Configuring dual monitors at HOME'
	xrandr --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output DP1 --off --output VGA1 --mode 1280x1024 --pos 1280x0 --rotate normal --primary
else
	echo 'Configuring dual monitors at WORK'
	xrandr --output DisplayPort-1 --mode 1280x1024 --pos 1280x0 --rotate normal --output DisplayPort-0 --mode 1280x1024 --pos 0x0 --rotate normal
fi
