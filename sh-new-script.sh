#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] script_name
Creates a new shell script (if it does not exist), or else opens the existing script.

OPTIONS
-f  Desired file name (.sh extension is used if none is given)
-n  Dry-run: doesn't create the script, only shows its full name
-h  Help"
	exit $1
}

V_SCRIPT_NAME=
V_DRY_RUN=
while getopts "f:nh" V_ARG ; do
	case $V_ARG in
	f)	V_SCRIPT_NAME=$OPTARG ;;
	n)	V_DRY_RUN="(DRY-RUN) " ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_SCRIPT_NAME" ] ; then
	# If it's not an option, we'll consider it text
	if [ "${1:0:1}" != '-' ] ; then
		V_SCRIPT_NAME="$1"
	fi
fi

if [ -z "$V_SCRIPT_NAME" ] ; then
	echo -e "Please suplly a script name with the -f option, or as the first argument in the command line.\n"
	usage 3
fi

open_script_file() {
	ls -l --color=auto $1
	if [ -z "$V_DRY_RUN" ] ; then
		subl $1 &
	fi
}

if [ -f "$V_SCRIPT_NAME" ] ; then
	echo "${V_DRY_RUN}Opening existing shell script $V_SCRIPT_NAME (full path: $(readlink -e $V_SCRIPT_NAME))"
	open_script_file $V_SCRIPT_NAME
	exit 0
fi

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
	exit 0
fi

echo "${V_DRY_RUN}Creating shell script $V_FULL_PATH"
if [ -n "$V_DRY_RUN" ] ; then
	exit 0
fi

echo '#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Here goes a brief description of the shell script.

OPTIONS
-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done' > $V_FULL_PATH
chmod +x $V_FULL_PATH
open_script_file $V_FULL_PATH
