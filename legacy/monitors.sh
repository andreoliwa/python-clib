#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Configure single or dual monitors using xrandr.

OPTIONS
-1  Single monitor
-2  Dual monitors (default option, if none given)
-h  Help"
	exit $1
}

V_SINGLE=
while getopts "12h" V_ARG ; do
	case $V_ARG in
	1)	V_SINGLE=1 ;;
	2)	V_SINGLE= ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

source ~/bin/.clitoolkitrc

if [ -n "$V_SINGLE" ] ; then
	V_WHAT='a single monitor'
else
	V_WHAT='dual monitors'
fi

set_panel_position() {
	# http://forum.xfce.org/viewtopic.php?id=7466
	xfconf-query -c xfce4-panel -p /panels/panel-0/output-name -s $1
}

if [ -n "$V_SINGLE" ] ; then
	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		echo "Configuring $V_WHAT at HOME"
		xrandr --output LVDS1 --mode 1280x800 --pos 0x0 --rotate normal --output DP1 --off --output VGA1 --off
		set_panel_position LVDS1
	else
		xrandr --output DisplayPort-1 --off --output DisplayPort-0 --mode 1280x1024 --pos 0x0 --rotate normal
	fi
else
	if [ $HOSTNAME = $G_HOME_COMPUTER ] ; then
		echo "Configuring $V_WHAT at HOME"
		xrandr --output VIRTUAL1 --off --output LVDS1 --mode 1280x800 --pos 1920x0 --rotate normal --output DP1 --off --output VGA1 --mode 1920x1080 --pos 0x0 --rotate normal
		set_panel_position VGA1
	else
		echo "Configuring $V_WHAT at WORK"
		xrandr --output DisplayPort-1 --mode 1280x1024 --pos 1280x0 --rotate normal --output DisplayPort-0 --mode 1280x1024 --pos 0x0 --rotate normal
	fi
fi
