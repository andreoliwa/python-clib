#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Restart the wireless mouse module ('usbhid', in fact).
Use this after resuming from suspend mode on Ubuntu 12.10 (mouse is freezing, probably a bug).

OPTIONS
-h   Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

sudo modprobe -r usbhid
sudo modprobe usbhid
