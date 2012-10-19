#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [-h]
Mostra os arquivos de um commit

OPCOES
-h   Ajuda
EOF
}

# Parse dos argumentos da linha de comando
while getopts "h" OPTION ; do
	case $OPTION in
	h)
		usage
		exit 1
		;;
	?)
		usage
		exit
		;;
	esac
done

V_COMMIT=$1
git show $V_COMMIT --name-only --pretty="format:" | tail -n+2
