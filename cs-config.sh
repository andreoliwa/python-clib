#!/bin/bash
usage() {
	cat << EOF
USO: [$(dirname $0)/]$(basename $0) [opcoes]
Mostra a configuracao do Code Sniffer.

OPCOES
-c   Configura Code Sniffer e hooks.
-h   Ajuda
EOF
}

# Parse dos argumentos da linha de comando
V_CONFIG=
while getopts "ch" OPTION ; do
	case $OPTION in
	c)
		V_CONFIG=1
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

exec_command() {
	V_COMMAND="$*"
	echo
	echo "$ $V_COMMAND"
	$V_COMMAND
}

exec_ls() {
	exec_command "ls -l --color=auto $*"
}

if [ -n "$V_CONFIG" ] ; then
	echo 'Configurando diretorio de padroes do Code Sniffer'
	cd /usr/share/php/PHP/CodeSniffer/Standards/
	sudo rm -v FolhaPEAR
	sudo ln -s $HOME/src/local/dev_bin/codesniffer/FolhaPEAR/

	echo 'Configurando pre-commit hook'
	cd $HOME/Dropbox/svn-repo/hooks
	rm -v pre-commit
	ln -s $HOME/src/local/dev_bin/codesniffer/pre-commit
	chmod a+x pre-commit

	echo 'Configurando diretorio de logs usado no pre-commit hook'
	sudo ln -s $HOME/Dropbox/dev_logs/ /srv
fi

exec_ls /usr/share/php/PHP/CodeSniffer/Standards/
exec_ls $HOME/Dropbox/svn-repo/hooks
exec_ls /srv/dev_logs
exec_command "which code-sniffer.sh"
exec_ls "$(which code-sniffer.sh)"
exec_ls "$(readlink $(which code-sniffer.sh))"
