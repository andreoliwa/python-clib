#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Creates a template from the "my-variables" file.

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

V_TEMPLATE_FILE=my-variables.tmpl
sed 's/\(export.\+=\).\+$/\1/' ~/bin/my-variables > $V_TEMPLATE_FILE
echo "Template file created: $(readlink -e $V_TEMPLATE_FILE)"
cat $V_TEMPLATE_FILE
