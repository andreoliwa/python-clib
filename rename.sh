#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [opcoes] [arquivo1 arquivo2 ...]
Renomeia arquivos recebidos na linha de comando e/ou via stdin.

OPCOES
-n   Dry run
-c   Camel case
-s   Slug
-h   Ajuda
EOF
	exit $1
}

# Parse dos argumentos da linha de comando
V_CASE_OPTION=
V_DRY_RUN=
while getopts "ncsh" OPTION ; do
	case $OPTION in
	n)	V_DRY_RUN=1 ;;
	c)	V_CASE_OPTION='-c' ;;
	s)	V_CASE_OPTION='-s' ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

if [ -z "$V_CASE_OPTION" ] ; then
	usage 3
fi

V_ALL_FILES=
while (( "$#" )) ; do
	# Se nao for uma opcao, e se for um arquivo valido
	#&& [ -f "$1" ]
	if [ "${1:0:1}" != '-' ] ; then
		if [ -z "$V_ALL_FILES" ] ; then
			V_ALL_FILES="$1"
		else
			V_ALL_FILES="$V_ALL_FILES
$1"
		fi
	fi

	# Remove o primeiro argumento da linha de comando
	shift
done

V_OLD_IFS=$IFS
IFS='
'
for V_FULL_PATH in $V_ALL_FILES ; do
	V_DIRNAME="$(dirname "$V_FULL_PATH")/"
	V_BASENAME=$(basename "$V_FULL_PATH")
	V_BASENAME_WITHOUT_EXTENSION="$(basename $(echo ${V_FULL_PATH%.*}))"

	# Tratamento especial para arquivos sem extensão
	V_EXTENSION="${V_FULL_PATH##*.}"
	if [ "$V_EXTENSION" == "$V_FULL_PATH" ] ; then
		V_EXTENSION=
	else
		V_EXTENSION=".${V_EXTENSION}"
	fi

	# Normaliza só o nome base, sem extensão
	V_NEW_BASENAME_WITHOUT_EXTENSION="$(normalize.sh ${V_CASE_OPTION} ${V_BASENAME_WITHOUT_EXTENSION} | sed -e 's/^-\+//' -e 's/-\+$//')"
	V_NEW_EXTENSION="$(echo "$V_EXTENSION" | tr '[:upper:]' '[:lower:]')"

	V_NEW_FULL_PATH="${V_DIRNAME}${V_NEW_BASENAME_WITHOUT_EXTENSION}${V_NEW_EXTENSION}"

	if [ "$V_FULL_PATH" != "$V_NEW_FULL_PATH" ] ; then
		if [ -z "$V_DRY_RUN" ] ; then
			mv -v "$V_FULL_PATH" "$V_NEW_FULL_PATH"
		else
			echo "(dry-run) $V_FULL_PATH -> $V_NEW_FULL_PATH"
		fi
	fi
done
IFS=$V_OLD_IFS
