#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-cuh] [<projeto>]
Query Sublime project files and show their project directories.
Se nenhum projeto for informado, mostra todos os diretorios de todos os projetos encontrados no Sublime.

-c  Ignora diretorio de classes comuns
-u  Ignora diretorio de testes unitarios e outros
-p  Mostra o caminho completo dos diretórios
-s  Mostra o sufixo escolhido no final de cada diretório
-g  Show all project's recent commits in Git
-h  Help"
	exit $1
}

V_IGNORE_COMMON=
V_IGNORE_UNIT_TESTS=
V_SHOW_FULL_PATH=
V_SUFFIX=
V_GIT=
while getopts "cups:gh" V_ARG ; do
	case $V_ARG in
	s)	V_SUFFIX=$OPTARG ;;
	c)	V_IGNORE_COMMON=1 ;;
	u)	V_IGNORE_UNIT_TESTS="-e mxzypkt" ;;
	p)	V_SHOW_FULL_PATH=1 ;;
	g)	V_GIT=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

# When Git option is chosen, all others should be set
if [ -n "$V_GIT" ] ; then
	V_IGNORE_COMMON=1
	V_IGNORE_UNIT_TESTS=1
	V_SHOW_FULL_PATH=1
fi

[ -n "$V_IGNORE_COMMON" ] && V_IGNORE_COMMON="-e classes$ -e includes$"
[ -n "$V_IGNORE_UNIT_TESTS" ] && V_IGNORE_UNIT_TESTS="-e mxzypkt"

V_PREFIX_CMD=
if [ -n "$V_SHOW_FULL_PATH" ] ; then
	V_PREFIX_CMD="sed s#^#${G_WORK_SRC_DIR}/#"
fi

V_SUFFIX_CMD=
if [ -n "$V_SUFFIX" ] ; then
	V_SUFFIX_CMD="sed s#\$#${V_SUFFIX}#"
fi

pushd $G_DROPBOX_DIR/code/sublime-projects/ >/dev/null
V_PROJECT_FILES=
for V_PROJECT in $* ; do
	[ "${V_PROJECT:0:1}" != '-' ] && [ "$V_PROJECT" != "$V_SUFFIX" ] && V_PROJECT_FILES="$V_PROJECT_FILES *$V_PROJECT*.sublime-project"
done
if [ -z "$V_PROJECT_FILES" ]; then
	V_PROJECT_FILES=*.sublime-project
fi

[ -z "$V_PREFIX_CMD" ] && V_PREFIX_CMD=cat
[ -z "$V_SUFFIX_CMD" ] && V_SUFFIX_CMD=cat
V_RESULTS="$(cat $V_PROJECT_FILES | grep -v '[ \t]*\/\/' | grep -o -e '/dev_.\+\"' | cut -b 2- | tr -d '"' | grep -v $V_IGNORE_COMMON $V_IGNORE_UNIT_TESTS - | sort -u | $V_PREFIX_CMD | $V_SUFFIX_CMD)"

popd >/dev/null

if [ -z "$V_GIT" ] ; then
	echo "$V_RESULTS"
else
	echo "Showing Git log for files under repository $PWD"
	echo "$V_RESULTS" | grep "$(basename $PWD)" | xargs git log --
fi
