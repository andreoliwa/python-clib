#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [opções]
Mostra usuários e seus ambientes.

OPTIONS
-u  Usuário (parte do login) ou número do ambiente
-h  Help"
	exit $1
}

V_USER='='
while getopts "n:u:h" V_ARG ; do
	case $V_ARG in
	u)
		V_USER=$OPTARG
		;;
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

lynx --dump $G_SVN_TECHNOTE_URL | grep -o '* [0-9]\{2,3\} =.\+' | cut -b 3- | grep --color=auto -e $V_USER
