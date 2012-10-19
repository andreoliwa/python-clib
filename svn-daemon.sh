#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [opcoes]
Descrição do script.

OPÇÕES
-h   Ajuda
EOF
	exit $1
}

# Argumentos da linha de comando
while getopts "h" V_ARG ; do
	case $V_ARG in
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

# https://help.ubuntu.com/community/Subversion

if [ -z "$(pidof svnserve)" ] ; then
	echo 'Iniciando svnserve'
	svnserve -d -r $HOME/Dropbox/svn-repo/
else
	echo 'AVISO: svnserve já foi iniciado'
fi

echo
ps aux | grep -v grep | grep -e ^USER -e svnserve
echo
svn info svn://localhost
