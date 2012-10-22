#!/bin/bash
if [ "$1" = '-f' ]; then
	date --rfc-3339=seconds
	V_SOURCE_FILE=$2
	echo "Origem  => $V_SOURCE_FILE"

	#if [[ $V_SOURCE_FILE != */dev_* ]]; then
	if [[ $V_SOURCE_FILE != $(echo $G_WORK_SRC_DIR)* ]]; then
		echo "Somente os arquivos do diretorio $G_WORK_SRC_DIR serao publicados..."
		exit 1
	fi

	V_DESTINATION_FILE=$(echo $V_SOURCE_FILE | sed 's@/local/@/remote/@' | sed 's@/dev_htdocs@@')
	echo Destino =\> $V_DESTINATION_FILE

	cp --force $V_SOURCE_FILE $V_DESTINATION_FILE
	echo Arquivo foi publicado no servidor de desenvolvimento.
	exit
fi

V_COMMON_DIRS='dev_htdocs/common dev_htdocs/webmaster.corp.folha.com.br/furniture'
V_PROJECTS="$*"
echo
echo "Publicando os seguintes projetos: $V_PROJECTS"

for PASS in {1..2} ; do
	echo
	echo "rsync $G_WORK_SRC_DIR -> $FOLHA_SRC_PUBLISH_DIR (passo $PASS)"

	V_COMMON_CMD="rsync -huzr --delete --progress --exclude-from=$G_WORK_SRC_DIR/dev_bin/.gitignore --exclude=_archive* --modify-window=2 --times --omit-dir-times"

	V_ALL_DIRS="$V_COMMON_DIRS $(project-folders.sh $V_PROJECTS)"
	for V_DIR in $V_ALL_DIRS ; do
		V_LOCAL_DIR="$G_WORK_SRC_DIR/$V_DIR/"
		#echo $V_LOCAL_DIR
		V_REMOTE_DIR=$(echo "$FOLHA_SRC_PUBLISH_DIR/$V_DIR/" | sed 's#dev_htdocs/##')
		if [ -d "$V_LOCAL_DIR" ] ; then
			mkdir -p "$V_REMOTE_DIR"
			#echo "$V_COMMON_CMD $V_LOCAL_DIR $V_REMOTE_DIR"
			V_SYNCED_FILES=$($V_COMMON_CMD "$V_LOCAL_DIR" "$V_REMOTE_DIR" | grep -v -e bytes/sec -e 'total size' -e 'sending incremental' -e '^$' -e 'xfer#')
			if [ -n "$V_SYNCED_FILES" ] ; then
				echo ">>> Publicando diretorio $V_DIR"
				echo "$V_SYNCED_FILES"
			fi
		fi
	done
done

# Copia ícone favorito e outros arquivos na raiz de http://webmaster
cp -vu $G_WORK_SRC_DIR/dev_htdocs/webmaster.corp.folha.com.br/* $FOLHA_SRC_PUBLISH_DIR/webmaster.corp.folha.com.br/ 2> /dev/null
