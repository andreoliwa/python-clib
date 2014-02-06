#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Compare source files from work to home office directories.

  -o  Show differences from the Home Office repository (usually called DevQA).
  -b  Show differences from the Object Oriented Boilerplate repository.
  -g  Change branches in the Object Oriented Boilerplate Git repository.
  -d  Show differences between the Boilerplate and Gandalf.
  -h  Help"
	exit $1
}

V_REPO_HOME_OFFICE=
V_REPO_BOILERPLATE=
V_CHANGE_BRANCHES=
V_DIFF_BETA=
while getopts "obgdh" V_ARG ; do
	case $V_ARG in
		o)	V_REPO_HOME_OFFICE=1 ;;
		b)	V_REPO_BOILERPLATE=1 ;;
		g)	V_CHANGE_BRANCHES=1 ;;
		d)	V_DIFF_BETA=1 ;;
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_BOILERPLATE_OO_DIR=$G_DROPBOX_DIR/src/boilerplate-oo

V_OLD_IFS=$IFS
IFS='
'

V_COMPARE=
if [ -n "$V_REPO_HOME_OFFICE" ] ; then
	V_COMPARE="$V_COMPARE
$G_DROPBOX_DIR/src/home-office/dev_bin/devqa
$G_DROPBOX_DIR/src/home-office/dev_htdocs/common/classes/
$G_DROPBOX_DIR/src/home-office/dev_htdocs/mxzypkt.corp.folha.com.br/_unittests
"
fi

if [ -n "$V_REPO_BOILERPLATE" ] ; then
	V_COMPARE="$V_COMPARE
$G_DROPBOX_DIR/src/boilerplate-oo/dev_htdocs/boilerplate.corp.folha.com.br/webapp/admin
$G_DROPBOX_DIR/src/boilerplate-oo/dev_htdocs/common/classes/
$G_DROPBOX_DIR/src/boilerplate-oo/dev_htdocs/common/classes/boilerplate
$G_DROPBOX_DIR/src/boilerplate-oo/dev_htdocs/common/includes/boilerplate
"
fi

if [ -n "$V_DIFF_BETA" ] ; then
	V_MELD_ARGS=
	echo "Comparing Boilerplate and Gandalf files:"
	V_FIND="find $G_WORK_SRC_DIR/dev_htdocs/boilerplate.corp.folha.com.br/webapp/admin/ -type f | grep -vi -e example -e boilerplate_"
	for V_BETA_FILE in $(eval "$V_FIND") ; do
		V_COMMON_FILE="$G_WORK_SRC_DIR/dev_htdocs/gandalf.corp.folha.com.br/$(echo $V_BETA_FILE | sed 's#\(/[^/]\+\)\{8\}/##')"

		V_PAIR=" --diff $V_BETA_FILE $V_COMMON_FILE"
		V_MELD_ARGS="${V_MELD_ARGS}${V_PAIR}"
	done
	eval "meld $V_MELD_ARGS"
	exit
fi

if [ -z "$V_COMPARE" ] ; then
	usage 3
fi

V_MELD_FILTER=$(find $G_WORK_SRC_DIR/dev_htdocs/common/classes/ -mindepth 1 -maxdepth 1 -type d -or \( -type f -and \( -iname 'geoip*' -or -iname 'enhance*' -or -iname 'lightopenid*' \) \) | sed 's#\(/[^/]\+\)\{7\}/##' | sort -u)
echo "Commons classes filter in Meld: "$V_MELD_FILTER

echo -e "\nComparing these directories:"
echo $V_COMPARE

if [ -n "$V_REPO_BOILERPLATE" ] && [ -n "$V_CHANGE_BRANCHES" ] ; then
	cd $V_BOILERPLATE_OO_DIR
	git co folha-boilerplate-atual
fi

V_MELD_ARGS=
for V_DIR in $V_COMPARE ; do
	V_FOLHA_DIR="$(echo "$V_DIR" | sed 's#\(/[^/]\+\)\{5\}/##')"
	V_HOME_OFFICE_DIR="$V_DIR"

	V_PAIR=" --diff $G_WORK_SRC_DIR/$V_FOLHA_DIR $V_HOME_OFFICE_DIR"
	echo $V_PAIR
	V_MELD_ARGS="${V_MELD_ARGS}${V_PAIR}"
	#diff -qN $G_WORK_SRC_DIR/$V_FOLHA_DIR $V_HOME_OFFICE_DIR
done
IFS=$V_OLD_IFS

meld $V_MELD_ARGS

if [ -n "$V_REPO_BOILERPLATE" ] && [ -n "$V_CHANGE_BRANCHES" ] ; then
	cd $V_BOILERPLATE_OO_DIR
	git co master
fi
