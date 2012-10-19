#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) -d <data> [-sh]
Retorna o nome do dia da semana, em portugues.

OPCOES
-d   data desejada
-s   nome curto
-h   ajuda
EOF
}

# Parse dos argumentos da linha de comando
V_SHORT=
V_DATE=
while getopts "d:sh" OPTION ; do
	case $OPTION in
		d)
			V_DATE=$OPTARG
			;;
		s)
			V_SHORT=1
			;;
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

V_DAY_OF_WEEK=$(date --date $V_DATE +%w)
V_DAY_NAME=
case $V_DAY_OF_WEEK in
	0)
		V_DAY_NAME=domingo
		;;
	1)
		V_DAY_NAME=segunda
		;;
	2)
		V_DAY_NAME=terca
		;;
	3)
		V_DAY_NAME=quarta
		;;
	4)
		V_DAY_NAME=quinta
		;;
	5)
		V_DAY_NAME=sexta
		;;
	6)
		V_DAY_NAME=sabado
		;;
esac
if [ -n "$V_SHORT" ] ; then
	echo ${V_DAY_NAME:0:3}
else
	echo $V_DAY_NAME
fi
