#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] script_name
Create a new shell script (if it does not exist), or else opens the existing script.

OPTIONS
-f  Desired file name (default .sh extension); you can use this option multiple times
-n  Dry-run: don't create the script, only show its full name
-h  Help"
	exit $1
}

V_ALL_SCRIPTS=
V_DRY_RUN=
while getopts "f:nh" V_ARG ; do
	case $V_ARG in
	f)	V_ALL_SCRIPTS="$V_ALL_SCRIPTS $OPTARG" ;;
	n)	V_DRY_RUN="(DRY-RUN) " ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_ALL_SCRIPTS" ] ; then
	# If it's not an option, we'll consider it text
	if [ "${1:0:1}" != '-' ] ; then
		V_ALL_SCRIPTS="$1"
	fi
fi

if [ -z "$V_ALL_SCRIPTS" ] ; then
	echo -e "Please suplly a script name with the -f option, or as the first argument in the command line.\n"
	usage 3
fi

open_script_file() {
	if [[ "${OSTYPE//[0-9.]/}" == 'darwin' ]]; then
		ls -lG $1
	else
		ls -l --color=auto $1
	fi
	if [ -z "$V_DRY_RUN" ] ; then
		atom $1 &
	fi
}

V_DEFAULT_TEXT='#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Type here your brief description of the shell script.

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done'

for V_SCRIPT_NAME in $V_ALL_SCRIPTS ; do
	if [ -f "$V_SCRIPT_NAME" ] ; then
		echo "${V_DRY_RUN}Opening existing shell script $V_SCRIPT_NAME (full path: $(readlink -e $V_SCRIPT_NAME))"
		open_script_file $V_SCRIPT_NAME
	else
		# Uses the .sh extension if the file doesn't have one
		V_EXTENSION="${V_SCRIPT_NAME##*.}"
		if [ "$V_EXTENSION" == "$V_SCRIPT_NAME" ] ; then
			V_SCRIPT_NAME=$V_SCRIPT_NAME.sh
		fi

		V_FULL_PATH=
		V_SCRIPT_DIR="$(dirname $V_SCRIPT_NAME)"
		if [ "$V_SCRIPT_DIR" = '.' ] ; then
			# If no directory was informed, then searches the path
			V_EXISTS="$(path-find.sh $V_SCRIPT_NAME)"
			if [ -f "$V_EXISTS" ] ; then
				V_FULL_PATH="$V_EXISTS"
			else
				V_FULL_PATH="$G_NEW_SCRIPTS_DIR/$V_SCRIPT_NAME"
			fi
		else
			V_FULL_PATH=$V_SCRIPT_NAME
		fi

		if [ -f "$V_FULL_PATH" ] ; then
			echo "${V_DRY_RUN}Opening existing shell script $V_FULL_PATH"
			open_script_file $V_FULL_PATH
		else
			echo "${V_DRY_RUN}Creating shell script $V_FULL_PATH"
			if [ -z "$V_DRY_RUN" ] ; then
	 			echo "$V_DEFAULT_TEXT" > $V_FULL_PATH
				chmod +x $V_FULL_PATH
				open_script_file $V_FULL_PATH
			fi
		fi
	fi
done
