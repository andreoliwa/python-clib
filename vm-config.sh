#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Configura uma VM, criando diretório .ssh/ e bin/, copiando .bashrc, etc.

How to use SSH without a password:
http://www.linuxproblem.org/art_9.html

Ordem de autenticação:
http://serverfault.com/questions/283722/authentication-order-with-ssh

Arquivo de configuração: ~/.ssh/config
Tem usuários default, hosts, opções de autenticação.
Veja o help com:
man ssh_config

-u  Usuário (default $G_WORK_UNIX_USERNAME).
-s  Nome curto do servidor / host / VM. Pode ser usado várias vezes.
-l  Listar servidores do arquivo de configuração.
-a  Configura todos os servidores do arquivo de configuração ssh.
-h  Help"
	exit $1
}

V_USERNAME=
V_ALL_HOSTS=
V_LIST_SERVERS=
V_CONFIG_ALL=
while getopts "u:s:lah" V_ARG ; do
	case $V_ARG in
		u)	V_USERNAME=$OPTARG ;;
		s)	V_ALL_HOSTS="${V_ALL_HOSTS} ${OPTARG}" ;;
		l)	V_LIST_SERVERS=1 ;;
		a)	V_CONFIG_ALL=1 ;;
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

if [ -n "$V_LIST_SERVERS" ] || [ -n "$V_CONFIG_ALL" ] ; then
	V_ALL_HOSTS="$(cat ~/.ssh/config | grep -v -e '^#' | grep -o -i 'hostname.\+' | cut -b 10- | sort | uniq)"

	# Se a opção escolhida foi só mostrar os servidores, mostra e sai
	if [ -n "$V_LIST_SERVERS" ] ; then
		echo "$V_ALL_HOSTS"
		exit 0
	fi

	# Se chegou aqui, a opção escolhida foi "configurar todos"
	# Junta todos em uma linha só, separados com espaços
	V_ALL_HOSTS="${V_ALL_HOSTS}"
fi

if [ -z "$V_USERNAME" ]; then
	V_USERNAME=$G_WORK_UNIX_USERNAME
	echo "Usuário default: $V_USERNAME"
fi

if [ -z "$V_ALL_HOSTS" ]; then
	echo 'Informe pelo menos um servidor com a opção -s'
	usage 3
fi

V_PUBLIC_KEY=~/.ssh/id_rsa.pub
if [ ! -f "$V_PUBLIC_KEY" ] ; then
	echo "A chave pública $V_PUBLIC_KEY não existe neste servidor"
	echo "Read the text below (how to use SSH without a password), and create a public key: http://www.linuxproblem.org/art_9.html"
	exit 4
fi

for V_HOST in $V_ALL_HOSTS ; do
	echo -e "${COLOR_LIGHT_BLUE}>>> Configurando servidor ${V_HOST}...${COLOR_NONE}"

	V_USERNAME_AT_HOST="$V_USERNAME@$V_HOST"

	echo 'Criando diretório .ssh e copiando chave pública'
	ssh $V_USERNAME_AT_HOST 'mkdir -p ~/.ssh'
	cat $V_PUBLIC_KEY | ssh $V_USERNAME_AT_HOST 'cat >> ~/.ssh/authorized_keys'

	#echo 'Eliminando duplicações'
	#ssh $V_USERNAME_AT_HOST 'cat ~/.ssh/authorized_keys | sort -u > ~/.ssh/authorized_keys'

	echo 'Copiando configurações para a VM'
	scp ~/.bashrc $V_USERNAME_AT_HOST:~
	V_SSH_CONFIG_COPY=~/.ssh/config-copy
	cat ~/.ssh/config | grep -v -e $V_HOST > $V_SSH_CONFIG_COPY
	scp $V_SSH_CONFIG_COPY $V_USERNAME_AT_HOST:~/.ssh/config
	rm $V_SSH_CONFIG_COPY

	echo 'Criando diretório de scripts'
	ssh $V_USERNAME_AT_HOST 'mkdir -p bin'

	echo 'Copiando alguns scripts'
	scp $(path-find.sh vm-config.sh) $V_USERNAME_AT_HOST:~/bin
done
