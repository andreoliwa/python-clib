#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Shut Dropbox down only when it's idle.

OPTIONS
-v  Verbose
-n  Dry-run
-h  Help"
	exit $1
}

V_VERBOSE=
V_DRY_RUN=
while getopts "vnh" V_ARG ; do
	case $V_ARG in
	v)	V_VERBOSE=1 ;;
	n)	V_DRY_RUN=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

[ -n "$V_VERBOSE" ] && echo "Waiting for Dropbox to be idle..."

V_STATUS=
while [ "$V_STATUS" != 'Idle' -a "$V_STATUS" != "Dropbox isn't running!" ] ; do
	sleep 1
	V_STATUS="$(dropbox status)"
	[ -n "$V_VERBOSE" ] && echo $V_STATUS
done

if [ -n "$V_DRY_RUN" ] ; then
	echo "(DRY-RUN) Would execute 'dropbox stop' here."
else
	dropbox stop
fi
