#!/bin/bash
usage() {
	echo "Usage: $(basename $0) <person> <project>
Compara os diretorios de uma pessoa da equipe com os meus."
	exit $1
}

V_PERSON=$1
V_PROJECT=$2
if [ -z "$V_PERSON" ] || [ -z "$V_PROJECT" ] ; then
	usage
	exit
fi

V_MY_ROOT=$G_WORK_SRC_DIR
V_HIS_ROOT=/folha/src/team

V_MELD_DIRS=
for V_SRC_DIR in $(project-folders.sh -u $V_PROJECT) ; do
	V_MY_DIR="${V_MY_ROOT}/${V_SRC_DIR}"
	V_HIS_DIR=$(echo "${V_HIS_ROOT}/${V_PERSON}/${V_SRC_DIR}/" | sed 's#dev_htdocs/##')
	echo "Comparando diretorio $V_MY_DIR com $V_HIS_DIR"
	V_MELD_DIRS="$V_MELD_DIRS --diff $V_MY_DIR $V_HIS_DIR"
done

if [ -z "$V_MELD_DIRS" ] ; then
	echo "Nao ha diretorios para comparar (pessoa: $V_PERSON, projeto $V_PROJECT)"
else
	meld $V_MELD_DIRS
fi
