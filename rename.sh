#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] [file1 file2 ...]
Rename files using slug or camel case notation.
Accept files from the command line or stdin.

OPTIONS
-n   Dry run
-s   rename-files-using-the-slug-notation
-c   RenameFilesUsingTheCamelCaseNotation
-e   Add string at the end of the filename (suffix before the extension)
-h   Help"
	exit $1
}

V_CASE_OPTION=
V_DRY_RUN=
V_SUFFIX=
while getopts "nsce:h" V_ARG ; do
	case $V_ARG in
	n)	V_DRY_RUN=1 ;;
	s)	V_CASE_OPTION='-s' ;;
	c)	V_CASE_OPTION='-c' ;;
	e)	V_SUFFIX=$OPTARG ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_CASE_OPTION" -a -z "$V_SUFFIX" ] ; then
	echo "Please choose slug, camel case, or a suffix."
	usage 3
fi

V_ALL_FILES=
while (( "$#" )) ; do
	# If it's not an option, assume it's a file
	if [ "${1:0:1}" != '-' -a "$1" != "$V_SUFFIX" ] ; then
		if [ -z "$V_ALL_FILES" ] ; then
			V_ALL_FILES="$1"
		else
			V_ALL_FILES="$V_ALL_FILES
$1"
		fi
	fi

	# Removes the first argument from the command line
	shift
done

V_OLD_IFS=$IFS
IFS='
'
for V_FULL_PATH in $V_ALL_FILES ; do
	V_DIRNAME="$(dirname "$V_FULL_PATH")/"
	V_BASENAME=$(basename "$V_FULL_PATH")
	V_BASENAME_WITHOUT_EXTENSION="$(basename $(echo ${V_FULL_PATH%.*}))"

	# Special treatment for files without extension
	V_EXTENSION="${V_FULL_PATH##*.}"
	if [ "$V_EXTENSION" == "$V_FULL_PATH" ] ; then
		V_EXTENSION=
	else
		V_EXTENSION=".${V_EXTENSION}"
	fi

	if [ -n "$V_CASE_OPTION" ] ; then
		# Normalizes only the basename without extension
		V_NEW_BASENAME_WITHOUT_EXTENSION="$(normalize.sh ${V_CASE_OPTION} ${V_BASENAME_WITHOUT_EXTENSION} | sed -e 's/^-\+//' -e 's/-\+$//')"
	else
		# Add the suffix before the extension
		V_NEW_BASENAME_WITHOUT_EXTENSION="${V_BASENAME_WITHOUT_EXTENSION}${V_SUFFIX}"
	fi

	# Lowercase extension
	V_NEW_EXTENSION="$(echo "$V_EXTENSION" | tr '[:upper:]' '[:lower:]')"

	V_NEW_FULL_PATH="${V_DIRNAME}${V_NEW_BASENAME_WITHOUT_EXTENSION}${V_NEW_EXTENSION}"

	if [ "$V_FULL_PATH" != "$V_NEW_FULL_PATH" ] ; then
		if [ -z "$V_DRY_RUN" ] ; then
			mv -v "$V_FULL_PATH" "$V_NEW_FULL_PATH"
		else
			echo "(DRY-RUN) $V_FULL_PATH -> $V_NEW_FULL_PATH"
		fi
	fi
done
IFS=$V_OLD_IFS
