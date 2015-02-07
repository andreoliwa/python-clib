#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Sample showing how to run a single instance of this script for each option

OPTIONS
-s  Slug that should be executed only once.
-h  Help"
	exit $1
}

V_SLUG=
while getopts "s:h" V_ARG ; do
	case $V_ARG in
	s)	V_SLUG=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_SLUG" ] ; then
	echo "Supply a slug with -s"
	usage 3
fi

echo "Chosen slug: $V_SLUG"

cli_lock() {
	V_PID_BASENAME=$1

	# The correct way would be to save the .pid file in /var/run, mas only the root user has access
	V_PID_FILE="/tmp/$V_PID_BASENAME.pid"
	if [ -f "$V_PID_FILE" ] ; then
		V_PID="$(cat "$V_PID_FILE")"
		if ps -p $V_PID > /dev/null ; then
			echo "There is already a script being executed: PID $V_PID ($V_PID_FILE)"
			exit 4
		fi
	fi

	# Saves the PID in a file
	echo "$$" > "$V_PID_FILE"
	echo "The PID of this script ($$) was saved in the file $V_PID_FILE"
}

cli_unlock() {
	# Call this at the end of your script, to clean up.
	# But, if you forget, no problem... everything will work anyway, in the next run.
	# The only thing is there will be some useless .pid files left in the directory.
	rm -vf "$V_PID_FILE" > /dev/null
}

cli_lock "$(basename $0)-$V_SLUG"

# Here you should write the code of your script (this is only a sample)
echo 'The script is doing something...'
sleep 10

cli_unlock
