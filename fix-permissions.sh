#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Fix PHP Code Sniffer permissions.

-h  Help"
	exit $1
}

while getopts "h" V_ARG ; do
	case $V_ARG in
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit 1
		;;
	esac
done

V_HOME_OFFICE_DIR="$G_DROPBOX_DIR/src/home-office/dev_bin/devqa"
V_CODE_SNIFFER_DIR="$G_WORK_SRC_DIR/dev_bin/devqa"
V_FILES="$V_CODE_SNIFFER_DIR/*.sh $V_CODE_SNIFFER_DIR/pre-commit $V_HOME_OFFICE_DIR/*.sh $V_HOME_OFFICE_DIR/pre-commit"
chmod a+x $V_FILES
ls -l --color=auto $V_FILES

echo
echo 'Testando...'
code-sniffer.sh

echo 'Permissões do cliente ssh...'
chmod -v 600 $HOME/.ssh/* $G_DROPBOX_DIR/linux/ssh*
