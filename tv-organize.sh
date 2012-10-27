#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Organiza filmes pela nota e duracao, gera movie.nfo, cria links para filmes e series.

  -n   Dry-run
  -v   Verbose
  -k   Apaga os diretorios de destino antes de comecar a organizar
  -i   Grava movie.nfo em vez de organizar os filmes
  -l   Cria links para os filmes e series que nao existem no diretorio principal
  -h   Ajuda"
}

V_DRY_RUN=
V_VERBOSE=
V_KILL=
V_SAVE_NFO=
V_MAKE_LINKS=
while getopts "nvkilh" OPTION ; do
	case $OPTION in
	n)
		V_DRY_RUN=1
		;;
	v)
		V_VERBOSE='-v'
		;;
	k)
		V_KILL=1
		;;
	i)
		V_SAVE_NFO=1
		;;
	l)
		V_MAKE_LINKS=1
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

V_OLD_IFS=$IFS
IFS='|
'

# http://wiki.xbmc.org/index.php?title=XBMC_databases#The_Video_Library
V_XBMC_MOVIE_DB=$HOME/.xbmc/userdata/Database/MyVideos60.db
V_MOVIES_DIR=$G_MOVIES_HDD/Movies
V_SERIES_DIR=$G_MOVIES_HDD/TV

if [ -n "$V_SAVE_NFO" ] ; then
	for V_XML in $(find "$V_MOVIES_DIR/All" -type f -iname '*.xml' | sort) ; do
		[ -n "$V_VERBOSE" ] && echo "Lendo $V_XML"

		V_IMDB_ID="$(cat $V_XML | grep -o -e '<id>[0-9t]\+' | cut -b 5-)"
		V_XML_URL=
		[ -n "$V_IMDB_ID" ] && V_XML_URL="http://www.imdb.com/title/$V_IMDB_ID"
		[ -n "$V_VERBOSE" ] && echo "  XML=$V_XML_URL"

		V_MOVIE_DIR="$(dirname "$V_XML")"
		V_NFO_FILE="$V_MOVIE_DIR/movie.nfo"

		if [ -f "$V_NFO_FILE" ]; then
			V_NFO_URL=$(cat "$V_NFO_FILE")
			if [ "$V_NFO_URL" == "$V_XML_URL" ] ; then
				[ -n "$V_VERBOSE" ] && echo "  Arquivo $V_NFO_FILE ja existe"
			else
				echo "AVISO: URLs diferentes"
				echo "  NFO=$V_NFO_URL  \"${V_NFO_FILE}\""
				echo "  XML=$V_XML_URL  \"${V_XML}\""
			fi
		else
			[ -n "$V_VERBOSE" ] && echo "  Gravando $V_NFO_FILE"
			[ -z "$V_DRY_RUN" ] && echo "$V_XML_URL" > $V_NFO_FILE
		fi
	done
	exit
fi

V_ALL_ROOTS="Both|Jaque|Wagner"

for V_ROOT in $V_ALL_ROOTS ; do
	V_RATING_ROOT_DIR="$V_MOVIES_DIR/${V_ROOT}-rating"
	V_DURATION_ROOT_DIR="$V_MOVIES_DIR/${V_ROOT}-duration"
	V_GENRE_ROOT_DIR="$V_MOVIES_DIR/${V_ROOT}-genre"

	if [ -n "$V_KILL" ] ; then
		[ -n "$V_VERBOSE" ] && echo "Apagando diretorio de notas $V_RATING_ROOT_DIR"
		[ -z "$V_DRY_RUN" ] && rm $V_VERBOSE -rf "$V_RATING_ROOT_DIR"

		[ -n "$V_VERBOSE" ] && echo "Apagando diretorio de duracoes $V_DURATION_ROOT_DIR"
		[ -z "$V_DRY_RUN" ] && rm $V_VERBOSE -rf "$V_DURATION_ROOT_DIR"

		[ -n "$V_VERBOSE" ] && echo "Apagando diretorio de generos $V_GENRE_ROOT_DIR"
		[ -z "$V_DRY_RUN" ] && rm $V_VERBOSE -rf "$V_GENRE_ROOT_DIR"
	fi

	# Cria links para seriados
	if [ -n "$V_MAKE_LINKS" ] ; then
		V_ALL_SERIES=$(diff -qr $V_SERIES_DIR/All/ $V_SERIES_DIR/$V_ROOT/ | grep -v -e "^Only in $V_SERIES_DIR/All" | grep '^Only in' | sed 's#\(/.\+\): #\1/#' | cut -b 9-)
		V_ALL_DIRS=
		for V_SERIES_DIR_FILE in $V_ALL_SERIES ; do
			[ -f "$V_SERIES_DIR_FILE" ] && V_ALL_DIRS="${V_ALL_DIRS}$(dirname "$V_SERIES_DIR_FILE")
"
			[ -d "$V_SERIES_DIR_FILE" ] && V_ALL_DIRS="${V_ALL_DIRS}${V_SERIES_DIR_FILE}
"
		done

		if [ -n "$V_ALL_DIRS" ]; then
			V_ALL_DIRS="${V_ALL_DIRS%?}"
			V_ALL_DIRS=$(echo "$V_ALL_DIRS" | sort | uniq)
			for V_SOURCE_DIR in $V_ALL_DIRS ; do
				V_TARGET_DIR="$(echo "$V_SOURCE_DIR" | sed "s#^$V_SERIES_DIR/$V_ROOT#$V_SERIES_DIR/All#")"
				[ -n "$V_VERBOSE" ] && echo "  Criando link de $V_SOURCE_DIR para $V_TARGET_DIR"
				[ -z "$V_DRY_RUN" ] && tv-ln.sh -s "$V_SOURCE_DIR" -t "$V_TARGET_DIR"
			done
		fi
	fi

	if [ ! -d "$V_MOVIES_DIR/$V_ROOT" ] && [ -n "$V_DRY_RUN" ] ; then
		V_ALL_MOVIES=$(echo "select strpath from movieview;" | sqlite3 $HOME/.xbmc/userdata/Database/MyVideos60.db | sort | uniq)
	else
		V_ALL_MOVIES=$(find "$V_MOVIES_DIR/$V_ROOT" -mindepth 1 -maxdepth 1 -type d | sort)
	fi

	for V_MOVIE_DIR in $V_ALL_MOVIES ; do
		[ -n "$V_VERBOSE" ] && echo "Processando $V_MOVIE_DIR"

		V_MOVIE_BASENAME=$(basename "$V_MOVIE_DIR")

		if [ -n "$V_MAKE_LINKS" ] ; then
			V_MAIN_MOVIE_DIR="$V_MOVIES_DIR/All/$V_MOVIE_BASENAME"
			if [ ! -d "$V_MAIN_MOVIE_DIR" ] ; then
				[ -n "$V_VERBOSE" ] && echo "  Criando link de $V_MOVIE_DIR para $V_MAIN_MOVIE_DIR"
				[ -z "$V_DRY_RUN" ] && tv-ln.sh -s "$V_MOVIE_DIR" -t "$V_MAIN_MOVIE_DIR"
			fi
		else
			V_ESCAPED_MOVIE_NAME=$(echo "$V_MOVIE_BASENAME" | tr "'" '%')
			V_INFO=$(echo "select c05, c11, c14, c09 from movieview where strpath like '%${V_ESCAPED_MOVIE_NAME}/';" | sqlite3 $V_XBMC_MOVIE_DB)

			# http://stackoverflow.com/a/5257398
			V_ARRAY_INFO=(${V_INFO//;/ })
			V_RATING=$(echo ${V_ARRAY_INFO[0]} | grep -o -e '[0-9]\+\.[0-9]')
			[ -z "$V_RATING" ] && V_RATING=0
			[ -n "$V_VERBOSE" ] && echo "  Nota=$V_RATING"

			V_DURATION=$(echo - | awk -v "S=${V_ARRAY_INFO[1]}" '{ printf "%02dh%02dm\n" , S % ( 60 * 60 ) / 60 , S % 60 }')
			[ -n "$V_VERBOSE" ] && echo "  Duracao=$V_DURATION"

			V_GENRE="${V_ARRAY_INFO[2]}"
			[ -n "$V_VERBOSE" ] && echo "  Genero=$V_GENRE"

			V_IMDB_ID="${V_ARRAY_INFO[3]}"
			V_IMDB_URL=
			[ -n "$V_IMDB_ID" ] && V_IMDB_URL="http://www.imdb.com/title/$V_IMDB_ID"
			[ -n "$V_VERBOSE" ] && echo "  IMDB=$V_IMDB_URL"

			V_SORT_NUMBER=$(echo "100 - ($V_RATING * 10)" | bc | cut -d '.' -f 1)
			V_SORT_NUMBER=$(printf '%03d\n' "$V_SORT_NUMBER")

			V_RATING_BASENAME="${V_SORT_NUMBER} ${V_RATING} ${V_DURATION}#$(basename "$V_MOVIE_DIR")"
			V_RATING_FULL_DIR="$V_RATING_ROOT_DIR/$V_RATING_BASENAME"
			[ -z "$V_DRY_RUN" ] && tv-ln.sh -s "$V_MOVIE_DIR" -t "$V_RATING_FULL_DIR"

			V_DURATION_BASENAME="${V_DURATION} ${V_RATING}#$(basename "$V_MOVIE_DIR")"
			V_DURATION_FULL_DIR="$V_DURATION_ROOT_DIR/$V_DURATION_BASENAME"
			[ -z "$V_DRY_RUN" ] && tv-ln.sh -s "$V_MOVIE_DIR" -t "$V_DURATION_FULL_DIR"

			for V_GENRE in $(echo "$V_GENRE" | tr -s ' /' '\n') ; do
				V_GENRE_DIRNAME="$V_GENRE_ROOT_DIR/$V_GENRE/$V_RATING_BASENAME"
				[ -z "$V_DRY_RUN" ] && tv-ln.sh -s "$V_MOVIE_DIR" -t "$V_GENRE_DIRNAME"
			done
		fi
	done
done

IFS=$V_OLD_IFS
