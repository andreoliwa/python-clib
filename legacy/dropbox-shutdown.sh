#!/bin/bash
V_LIMIT=5
V_SECONDS=1

usage() {
	echo "Usage: $(basename $0) [options]
Shut Dropbox down only when it's idle.

OPTIONS
-q  Quiet
-n  Dry-run
-i  Number of consecutive idle status until Dropbox is stopped (default: $V_LIMIT)
-s  Seconds do sleep between Dropbox poll (default: $V_SECONDS)
-h  Help"
	exit $1
}

V_QUIET=
V_DRY_RUN=
while getopts "qni:s:h" V_ARG ; do
	case $V_ARG in
	q)	V_QUIET=1 ;;
	n)	V_DRY_RUN=1 ;;
	i)	V_LIMIT=$(( ${OPTARG#0} + 0 )) ;;
	s)	V_SECONDS=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

[ -z "$V_QUIET" ] && echo "Waiting $V_LIMIT rounds for Dropbox to be idle..."

V_STATUS=
V_COUNT=0
while [ true ] ; do
	sleep $V_SECONDS

	if [ "$V_STATUS" == "Dropbox isn't running!" ] ; then
		exit
	fi

	if [ "$V_STATUS" == 'Idle' -o "$V_STATUS" == 'Up to date' ] ; then
		V_COUNT=$(( $V_COUNT + 1 ))
		[ -z "$V_QUIET" ] && echo "Idle count: $V_COUNT"

		if [ $V_COUNT -ge $V_LIMIT ] ; then
			[ -z "$V_QUIET" ] && echo "Idle limit reached, exiting"
			break
		fi
	else
		# If there's any other Dropbox activity, reset the count
		V_COUNT=0
	fi

	V_STATUS="$(dropbox status)"
	[ -z "$V_QUIET" ] && echo $V_STATUS
done

if [ -n "$V_DRY_RUN" ] ; then
	echo "(DRY-RUN) Would execute 'dropbox stop' here."
else
	dropbox stop
fi
