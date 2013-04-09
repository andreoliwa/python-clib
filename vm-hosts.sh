#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Copia os hosts da vm206 para a máquina local.

OPÇÕES
-c  Copia os hosts da vm206.
-e  Edita o arquivo com os hosts extras.
-h  Help"
	exit $1
}

# Argumentos da linha de comando
V_COPY_HOSTS=
V_EDIT_EXTRA=
while getopts "ceh" V_ARG ; do
	case $V_ARG in
	c)	V_COPY_HOSTS=1 ;;
	e)	V_EDIT_EXTRA=1 ;;
	h)	usage 1 ;;
	?)	usage 2 ;;
	esac
done

V_VM206=/tmp/hosts-vm206
V_NEW=/tmp/hosts-new
V_EXTRA_FILE=$G_DROPBOX_DIR/linux/hosts-extra

if [ -n "$V_EDIT_EXTRA" ] ; then
	echo "Editando o arquivo de hosts extras $V_EXTRA_FILE"
	subl --wait $V_EXTRA_FILE
else
	if [ -z "$V_COPY_HOSTS" ] ; then
		usage 3
	fi
fi

echo 'Removendo temporários...'
rm $V_NEW /tmp/hosts* 2> /dev/null

echo 'Criando novo arquivo hosts...'
echo "#===================================================================================================
# NÃO ALTERE ESTE ARQUIVO MANUALMENTE!!!
# Ele foi gerado pelo script $0
#===================================================================================================" >> $V_NEW

echo "# IP da máquina local, gerado automaticamente
127.0.0.1		localhost" >> $V_NEW
echo "127.0.0.1		$HOSTNAME" >> $V_NEW

echo "
#===================================================================================================
# Outros IPs, copiados automaticamente do arquivo $V_EXTRA_FILE
#===================================================================================================" >> $V_NEW
cat $V_EXTRA_FILE >> $V_NEW

echo "
#===================================================================================================
# IPs dos servidores, copiados automaticamente da vm206 pelo script $0
#===================================================================================================" >> $V_NEW

echo 'Copiando hosts da vm206...'
scp vm206:/etc/hosts $V_VM206

echo 'Concatenando com o hosts atual...'
cat $V_VM206 | grep -vi -e localhost -e vm206 -e ip6 >> $V_NEW
sudo cp $V_NEW /etc/hosts

echo 'Feito.'
ls -l --color=auto /etc/hosts
