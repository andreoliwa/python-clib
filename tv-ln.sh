#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Cria hardlinks para um diretorio de filmes.

-s  Diretorio origem
-t  Diretorio alvo
-r  Nova raiz (Wagner, Jaque, Both)
-m  Caminho do filme ou legenda (resultado de um find)
-h  Help"
	exit $1
}

V_SOURCE_DIR=
V_TARGET_DIR=
V_NEW_ROOT_PLACE=
V_MOVIE_FILE=
while getopts "s:t:r:m:h" V_ARG ; do
	case $V_ARG in
	s)
		V_SOURCE_DIR=$OPTARG
		;;
	t)
		V_TARGET_DIR=$OPTARG
		;;
	r)
		V_NEW_ROOT_PLACE=$OPTARG
		;;
	m)
		V_MOVIE_FILE=$OPTARG
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

if [ -n "$V_SOURCE_DIR" ] && [ -n "$V_TARGET_DIR" ] ; then
	V_OLD_IFS=$IFS
	IFS='
'
	# Cria os subdiretorios da origem no diretorio destino
	cd "$V_SOURCE_DIR"
	mkdir -p "$V_TARGET_DIR"
	for V_SUBDIR in $(find . -mindepth 1 -type d | cut -b 3-) ; do
		mkdir -p "$V_TARGET_DIR/$V_SUBDIR"
	done

	# Cria um hardlink para cada arquivo origem
	for V_EACH_FILE in $(find . -type f | cut -b 3-) ; do
		ln -v "$V_EACH_FILE" "$V_TARGET_DIR/$V_EACH_FILE" 2> /dev/null
	done

	IFS=$V_OLD_IFS
fi

if [ -n "$V_NEW_ROOT_PLACE" ] && [ -n "$V_MOVIE_FILE" ] ; then
	V_MOVIE_BASENAME=$(basename "${V_MOVIE_FILE}")
	V_MOVIE_DIRNAME=$(dirname "${V_MOVIE_FILE}")
	V_MOVIE_NEW_DIRNAME=$(echo $V_MOVIE_DIRNAME | sed s@/All/@/${V_NEW_ROOT_PLACE}/@)
	V_MOVIE_NEW_FILENAME=$V_MOVIE_NEW_DIRNAME/$V_MOVIE_BASENAME

	#echo mkdir -p "'${V_MOVIE_NEW_DIRNAME}'"
	mkdir -p "${V_MOVIE_NEW_DIRNAME}"

	#echo ln "'${V_MOVIE_FILE}'" "'${V_MOVIE_NEW_FILENAME}'"
	V_ALREADY_EXISTS=
	if [ -f "${V_MOVIE_NEW_FILENAME}" ] ; then
		V_ALREADY_EXISTS='... ja existe'
	else
		ln "${V_MOVIE_FILE}" "${V_MOVIE_NEW_FILENAME}"
	fi
	echo "'${V_MOVIE_NEW_FILENAME}'"$V_ALREADY_EXISTS
fi
