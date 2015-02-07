#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Mostra revisoes recentes do SVN (por repositorio e usuario).

-n  Mostra somente os numeros das revisoes (o default e mostrar comentarios e tudo o mais).
-1  Mostra somente uma linha por revisao.
-w  Mostra somente as URLs do SVN web.
-s  Repositorio SVN (default todos: dev_bin e dev_htdocs).
-u  Login (completo ou parcial) de um usuario SVN (default: todos os usuarios).
-d  Numero de dias atras, para pesquisar nos logs (default: ultimas 24 horas a partir de agora).
-r  Numero de revisao inicial; se informado, a data acima e ignorada.
-v  Verbose
-h  Help"
	exit $1
}

V_NUMBER_ONLY=
V_ONE_LINE=
V_URL=
V_REPOS=
V_USER=' ' # O default precisa ser um espaco, por causa de um grep la embaixo
V_START_DATE=
V_REVISION=
V_VERBOSE=
while getopts "hn1ws:u:d:r:v" V_ARG ; do
	case $V_ARG in
		n)	V_NUMBER_ONLY=1 ;;
		1)	V_ONE_LINE=1 ;;
		w)	V_URL=1 ;;
		s)	V_REPOS=$OPTARG ;;
		u)	V_USER=$OPTARG ;;
		d)	V_START_DATE=$OPTARG ;;
		r)	V_REVISION=$OPTARG ;;
		v)	V_VERBOSE=1 ;;
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

if [ -z "$V_START_DATE" ] ; then
	V_START_DATE=0
fi
V_START_DATE=$(date --date="$V_START_DATE days ago" +%F)

if [ -z "$V_REVISION" ] ; then
	V_QUERY="-rHEAD:{$V_START_DATE}"
else
	V_QUERY="-rHEAD:$V_REVISION"
fi

if [ -z "$V_REPOS" ] ; then
	V_REPOS='dev_bin dev_htdocs'
fi

for V_REPO in $V_REPOS ; do
	if [ -n "$V_NUMBER_ONLY" ] ; then
		# Ultimas revisoes de um usuario, somente numeros
		V_CMD="svn log $G_SVN_URL/$V_REPO $V_QUERY -q | grep -v -e '----------' | grep '$V_USER' | cut -d ' ' -f 1 | cut -b 2-"
	elif [ -n "$V_URL" ] ; then
		# Ultimas revisoes de um usuario, uma linha por revisao, com URL
		V_CMD="svn log $G_SVN_URL/$V_REPO $V_QUERY -q | grep -v -e '----------' | grep '$V_USER' | cut -d ' ' -f 1 | cut -b 2- | sed 's#^#http://svn.ops.corp.folha.com.br/wsvn/revision.php?repname=${V_REPO}\&rev=#'"
	elif [ -n "$V_ONE_LINE" ] ; then
		# Ultimas revisoes de um usuario, uma linha por revisao
		svn log $G_SVN_URL/$V_REPO $V_QUERY -q | grep -v -e '----------' | grep "$V_USER" | sed "s/^/${V_REPO} | /"
		echo 3
	else
		# Ultimas revisoes de um usuario, com comentario e tudo
		V_CMD="svn log $G_SVN_URL/$V_REPO $V_QUERY | sed -n '/$V_USER/,/-----$/ p'"
	fi

	[ -n "$V_VERBOSE" ] && echo -e "\nComando executado: $V_CMD"
	eval $V_CMD
	[ -n "$V_VERBOSE" ] && echo -e "\nComando executado: $V_CMD"
done
