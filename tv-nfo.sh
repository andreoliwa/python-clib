#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Cria um arquivo movie.nfo no diretorio recebido via stdin (resultado da busca com tv-find-movie.sh).
Exemplo:
tv-find-movie.sh filme | $(basename $0) -i 12345

-i  URL ou id do filme no IMDB
-h  Help"
	exit $1
}

V_ID=
while getopts "hi:" V_ARG ; do
	case $V_ARG in
	i)
		V_ID=$OPTARG
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

if [ -z "$V_ID" ] ; then
	echo 'AVISO: Informe o ID ou URL do filme.'
	usage
	exit 2
fi

V_URL="http://www.imdb.com/title/tt$(echo "$V_ID" | grep -o '[0-9]\+')"
V_MOVIE_DIR="$(cat)"
echo $V_URL > "$V_MOVIE_DIR/movie.nfo"
echo "Arquivo $V_MOVIE_DIR/movie.nfo criado com o seguinte conteudo:"
cat "$V_MOVIE_DIR/movie.nfo"