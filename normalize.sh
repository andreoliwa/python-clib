#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options] texto
Muda o case do texto recebido.

  -c   Camel case
  -s   Slug
  -h   Ajuda"
	exit $1
}

V_CAMEL_CASE=
V_SLUG=
while getopts "csh" OPTION ; do
	case $OPTION in
	c)	V_CAMEL_CASE=1 ;;
	s)	V_SLUG=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_CAMEL_CASE" ] && [ -z "$V_SLUG" ] ; then
	echo 'Escolha camel case (-c) ou slug (-s)'
	usage 2
fi

V_TEXT=
while (( "$#" )) ; do
	# Se nao for uma opcao, eh texto
	if [ "${1:0:1}" != '-' ] ; then
		V_TEXT="$V_TEXT $1"
	fi

	# Remove o primeiro argumento da linha de comando
	shift
done
V_TEXT="${V_TEXT:1}"

if [ -n "$V_SLUG" ]; then
	echo $V_TEXT | sed -e 's/\([A-Z][a-z0-9]\)/-\1/g' -e 's/^-//' | tr '[:upper:]' '[:lower:]' | tr --squeeze-repeats '_()#.,;:/?~^[]{} ' '-' | sed 'y/àáâãèéìíòóôõÔúç/aaaaeeiiooooouc/'
fi

if [ -n "$V_CAMEL_CASE" ]; then
	V_OLD_IFS=$IFS
	IFS='_- '
	V_NEW_TEXT=
	for V_WORD in $V_TEXT ; do
		V_NEW_WORD=$(echo $V_WORD | tr '[:upper:]' '[:lower:]' | awk 'BEGIN{OFS=FS=""}{$1=toupper($1);print}')
		V_NEW_TEXT="$V_NEW_TEXT $V_NEW_WORD"
	done
	echo "${V_NEW_TEXT:1}"
	IFS=$V_OLD_IFS
fi
