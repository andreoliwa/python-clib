#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Run tests whenever a Python file is modified.
Thanks to: http://superuser.com/questions/181517/how-to-execute-a-command-whenever-a-file-changes

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)  usage 1 ;;
	?)  usage 2 ;;
	esac
done

if [ -z "$(type -p inotifywait)" ] ; then
	echo "inotifywait is not installed. Aborting."
	usage 3
fi

V_DIRECTORY="$PWD"
V_PROJECT="$(basename $V_DIRECTORY)"
V_PYGUARD_LOG=/tmp/pyguard.log
echo "Watched directory (and subdirs): $V_DIRECTORY"

# Add to the Python path all dirs that contains Python files
V_ALL_DIRS=$(find $PWD -type f -name *.py -exec dirname {} \; | sort -u | grep -v /tests | tr "\\n" ":") #
[ -n "$PYTHONPATH" ] && V_ALL_DIRS=":${V_ALL_DIRS}"
export PYTHONPATH="${PYTHONPATH}${V_ALL_DIRS%?}"
echo "Python module path (PYTHONPATH variable): $PYTHONPATH"

while true ; do
	V_CHANGE="$(inotifywait --quiet --event close_write,moved_to,create --recursive $V_DIRECTORY)"
	V_CHANGE=${V_CHANGE#./ * }
	if [[ "$V_CHANGE" =~ .+\.py$ ]] ; then
		V_DIRNAME="$(echo "$V_CHANGE" | cut -f 1 -d ' ')"
		V_FILENAME="$(echo "$V_CHANGE" | cut -f 3 -d ' ')"
		echo
		echo "Changed file: ${V_DIRNAME}${V_FILENAME}"

		if [[ "$V_CHANGE" =~ test_.+\.py$ ]] ; then
			V_TEST_PATH="${V_DIRNAME}${V_FILENAME}"
		else
			V_TEST_PATH="${V_DIRNAME}tests/test_${V_FILENAME}"
		fi

		if [ ! -f "$V_TEST_PATH" ] ; then
			notify-send --expire-time=500 --urgency=low --icon=error 'PyTest results' "Test file not found: ${V_TEST_PATH}"
		else
			pytest --color "$V_TEST_PATH" >$V_PYGUARD_LOG 2>&1
			if [ $? -eq 0 ] ; then
				V_ICON=info
			else
				V_ICON=error
			fi

			V_ALL_RESULTS="$(<$V_PYGUARD_LOG)"
			echo
			echo "$V_ALL_RESULTS"

			# http://unix.stackexchange.com/questions/4527/program-that-passes-stdin-to-stdout-with-color-codes-stripped
			V_LAST_LINES="$(echo "$V_ALL_RESULTS" | perl -pe 's/\e\[?.*?[\@-~]//g' | head -n -1 | tail -n 3)"

			# Expire time doesn't work
			# http://askubuntu.com/questions/110969/notify-send-ignores-timeout
			notify-send --expire-time=500 --urgency=low --icon=$V_ICON "PyTest results ($V_PROJECT)" "${V_LAST_LINES}"
		fi
	fi
done
