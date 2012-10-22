#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [opcoes]
Compara o código fonte da Folha com os diretórios de home office.
Sou um idiota mesmo por me importar com essa merda toda.

OPÇÕES
-o   Mostrar diferenças do repositório Home Office (geralmente DevQA).
-b   Mostrar diferenças do repositório Boilerplate OO.
-g   Mudar de branches no Git do boilerplate OO.
-d   Diferenças entre as classes beta do Gandalf e o Boilerplate oficial.
-h   Ajuda
EOF
	exit $1
}

# Argumentos da linha de comando
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

V_LOCAL_DIR=$HOME/src/local
V_BOILERPLATE_OO_DIR=$HOME/Dropbox/src/boilerplate-oo

V_OLD_IFS=$IFS
IFS='
'

V_COMPARE=
if [ -n "$V_REPO_HOME_OFFICE" ] ; then
	V_COMPARE="$V_COMPARE
$HOME/Dropbox/src/home-office/dev_bin/devqa
$HOME/Dropbox/src/home-office/dev_htdocs/common/classes/
$HOME/Dropbox/src/home-office/dev_htdocs/mxzypkt.corp.folha.com.br/_unittests
"
fi

if [ -n "$V_REPO_BOILERPLATE" ] ; then
	V_COMPARE="$V_COMPARE
$HOME/Dropbox/src/boilerplate-oo/dev_htdocs/boilerplate.corp.folha.com.br/webapp/admin
$HOME/Dropbox/src/boilerplate-oo/dev_htdocs/common/classes/
$HOME/Dropbox/src/boilerplate-oo/dev_htdocs/common/classes/boilerplate
$HOME/Dropbox/src/boilerplate-oo/dev_htdocs/common/includes/boilerplate
"
fi

if [ -n "$V_DIFF_BETA" ] ; then
	V_MELD_ARGS=
	echo "Comparando Gandalf e classes comuns:"
	for V_BETA_FILE in $(find $(project-folders.sh -cup gandalf) -type f -iname '*beta_*') ; do
		V_NEW_CLASS=_
		[ "$(basename $V_BETA_FILE)" = "beta_render.class.php" ] && V_NEW_CLASS=

		V_COMMON_FILE="$V_LOCAL_DIR/dev_htdocs/common/classes/$(basename $V_BETA_FILE | sed "s/beta/${V_NEW_CLASS}spiffy/")"

		V_PAIR=" --diff $V_BETA_FILE $V_COMMON_FILE"
		echo $V_PAIR
		V_MELD_ARGS="${V_MELD_ARGS}${V_PAIR}"
	done
	eval "meld $V_MELD_ARGS"
	exit
fi

if [ -z "$V_COMPARE" ] ; then
	usage 3
fi

V_MELD_FILTER=$(find $HOME/src/local/dev_htdocs/common/classes/ -mindepth 1 -maxdepth 1 -type d -or \( -type f -and \( -iname 'geoip*' -or -iname 'enhance*' -or -iname 'lightopenid*' \) \) | sed 's#\(/[^/]\+\)\{7\}/##' | sort -u)
echo "Filtro de classes comuns no Meld: "$V_MELD_FILTER

echo -e "\nComparando estes diretorios:"
echo $V_COMPARE

if [ -n "$V_REPO_BOILERPLATE" ] && [ -n "$V_CHANGE_BRANCHES" ] ; then
	cd $V_BOILERPLATE_OO_DIR
	git co folha-boilerplate-atual
fi

V_MELD_ARGS=
for V_DIR in $V_COMPARE ; do
	V_FOLHA_DIR="$(echo "$V_DIR" | sed 's#\(/[^/]\+\)\{5\}/##')"
	V_HOME_OFFICE_DIR="$V_DIR"

	V_PAIR=" --diff $V_LOCAL_DIR/$V_FOLHA_DIR $V_HOME_OFFICE_DIR"
	echo $V_PAIR
	V_MELD_ARGS="${V_MELD_ARGS}${V_PAIR}"
	#diff -qN $V_LOCAL_DIR/$V_FOLHA_DIR $V_HOME_OFFICE_DIR
done
IFS=$V_OLD_IFS

meld $V_MELD_ARGS

if [ -n "$V_REPO_BOILERPLATE" ] && [ -n "$V_CHANGE_BRANCHES" ] ; then
	cd $V_BOILERPLATE_OO_DIR
	git co master
fi
