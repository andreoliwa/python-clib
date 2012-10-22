#!/bin/bash
usage() {
	cat << EOF
USAGE: [$(dirname $0)/]$(basename $0) [options]
Creates a new shell script (if it does not exist), or else opens the existing script.

OPTIONS
-h   Help
EOF
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_SCRIPT_FILE="$1"
if [ -z "$V_SCRIPT_FILE" ] ; then
	echo "Please suplly a script name with an '.sh' extension"
	usage 3
fi

if [ -f "$V_SCRIPT_FILE" ] ; then
	echo "Opening shell script $(readlink -e $V_SCRIPT_FILE)"
else
	V_DIR="$(dirname $V_SCRIPT_FILE)"
	if [ "$V_DIR" = '.' ] ; then
		V_DIR=$G_NEW_SCRIPTS_DIR
		V_SCRIPT_FILE="$V_DIR/$V_SCRIPT_FILE"
	fi

	if [ -f "$V_SCRIPT_FILE" ] ; then
		echo "Opening shell script $V_SCRIPT_FILE in $V_DIR directory"
	else
		echo "Creating shell script $V_SCRIPT_FILE"
		echo '#!/bin/bash
usage() {
	cat << EOF
USAGE: [$(dirname $0)/]$(basename $0) [options]
Here goes a brief description of the shell script.

OPTIONS
-h   Help
EOF
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done' > $V_SCRIPT_FILE
		chmod +x $V_SCRIPT_FILE
	fi
fi

ls -l --color=auto $V_SCRIPT_FILE
subl $V_SCRIPT_FILE &
