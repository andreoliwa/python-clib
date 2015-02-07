#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Check ID3 tags in music files.

OPTIONS
-q  Quiet (show errors only)
-u  Check less info for unknown albums
-g  List of desired genres (separated with commas)
-t  Open a terminal window for each directory with wrong tags
-h  Help"
	exit $1
}

V_QUIET=
V_UNKNOWN=
V_SHOW_GENRES=
V_DESIRED_GENRES=
V_TERMINAL=
while getopts "qug:th" V_ARG ; do
	case $V_ARG in
	q)	V_QUIET=1 ;;
	u)	V_UNKNOWN=1 ;;
	g)	V_SHOW_GENRES=1 && V_DESIRED_GENRES=$OPTARG ;;
	t)	V_TERMINAL=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -n "$V_SHOW_GENRES" ] ; then
	V_GENRES_TWO_COLUMNS="$(eyeD3 --no-color-P genres)"
	#@todo echo "$V_DESIRED_GENRES"

	V_FLAT="$(echo "$V_GENRES_TWO_COLUMNS" | cut -b 1-40 | sed 's/ \+$//')
$(echo "$V_GENRES_TWO_COLUMNS" | cut -b 41-)"
	echo "$V_FLAT"
	exit
fi

check_tag() {
	V_TYPE=$1
	V_TAG=$2
	V_REGEX=$3
	V_OPTION=$4

	V_ERROR=

	#V_DATA="$(eyeD3 --no-color --rfc822 *.mp3 | grep -e '^Artist:' -e '^Album:' -e '^Genre:' -e '^Year:' | sort -u)"
	V_DATA="$(echo "$V_ID3" | grep -o -e "$V_REGEX" | sort -u)"
	V_COUNT=$(echo "$V_DATA" | wc -l)

	if [ $V_COUNT -lt 1 -o -z "$V_DATA" ] ; then
		if [ "$V_TAG" == 'grouping' ] ; then
			# A missing grouping tag is not an error
			return
		else
			V_ERROR="$V_TYPE: Missing $V_TAG (eyeD3 --to-v2.3 $V_OPTION)"
		fi
	fi

	if [ "$V_TYPE" == 'Directory' ] ; then
		if [ $V_COUNT -gt 1 ] ; then
			# http://www.thegeekstuff.com/2009/11/unix-sed-tutorial-multi-line-file-operation-with-6-practical-examples/
			V_ERROR="$V_TYPE: Duplicated $V_TAG (eyeD3 --to-v2.3 $V_OPTION): $(echo "$V_DATA" | sed -e 's/^.\+: //g' | sed '/./=' | sed 'N; s/\n/. /' | tr "\\n" " ")"
		fi
	fi

	if [ -n "$V_ERROR" ] ; then
		V_WRONG="${V_WRONG}
${V_ERROR}"
	else
		V_RIGHT="$V_RIGHT
${V_DATA}"
	fi
}

V_OLD_IFS=$IFS
IFS='
'
for V_DIR in $(find "$PWD" -type d) ; do
	cd $V_DIR
	V_COUNT=$(ls -1 *.mp3 2>/dev/null | wc -l)
	if [ $V_COUNT -eq 0 ] ; then
		continue
	fi

	V_RIGHT=
	V_WRONG=

	V_ID3="$(eyeD3 --no-color *.mp3 2>/dev/null)"
	check_tag 'Directory' 'artist' '^artist: .\+' -a
	check_tag 'Directory' 'album' '^album: .\+' -A
	check_tag 'Directory' 'recording date' '^recording date: .\+' '--recording-date'

	for V_FILE in $(find "${V_DIR}" -maxdepth 1 -type f -name '*.mp3') ; do
		V_ID3="$(eyeD3 --no-color -v "$V_FILE" 2>/dev/null)"
		V_BASENAME="$(basename "$V_FILE")"

		check_tag "File $V_BASENAME" 'artist' '^artist: .\+' -a
		check_tag "File $V_BASENAME" 'album' '^album: .\+' -A
		check_tag "File $V_BASENAME" 'genre' 'genre: .\+' -G
		check_tag "File $V_BASENAME" 'original release date' '^original release date: .\+' '--orig-release-date'
		check_tag "File $V_BASENAME" 'recording date' '^recording date: .\+' '--recording-date'
		check_tag "File $V_BASENAME" 'title' '^title: .\+' -t
		check_tag "File $V_BASENAME" 'track' '^track:\s\+[0-9]\+' -n

		if [ -z "$V_UNKNOWN" ] ; then
			check_tag "File $V_BASENAME" 'bpm' '^BPM: [1-9]$' '--bpm'

			V_ID3="$(id3v2 -l $V_FILE)"
			check_tag "File $V_BASENAME" 'grouping' '^TIT1.\+' '--text-frame TIT1:xxx'
		fi
	done

	V_RIGHT="$(echo "${V_RIGHT:1}" | grep -v -e '^track' -e '^title' | sort -u)"

	if [ -n "$V_WRONG" ] ; then
		if [ -n "$V_TERMINAL" ] ; then
			# http://stackoverflow.com/questions/4465930/prevent-gnome-terminal-from-exiting-after-execution
			gnome-terminal --maximize --working-directory="$V_DIR" --command "bash -c '$(basename $0); bash -i'"
		else
			# Show errors only if not opening terminal windows
			echo "---------- ${V_DIR}"
			echo -e "${COLOR_LIGHT_RED}${V_WRONG:1}${COLOR_NONE}"
			echo -e "${COLOR_GREEN}${V_RIGHT}${COLOR_NONE}"
		fi
	elif [ -z "$V_QUIET" ] ; then
		echo "---------- ${V_DIR}"
		echo -e "${COLOR_GREEN}${V_RIGHT}${COLOR_NONE}"
	fi
done

IFS=$V_OLD_IFS
