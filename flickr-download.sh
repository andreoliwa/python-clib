#!/bin/bash
V_DIR=$G_DOWNLOAD_DIR/Flickr
mkdir -p $V_DIR
cd $V_DIR

for V_URL in $(cat) ; do
	echo "Lendo URL do Flickr: $V_URL"

	V_TITLE=$(lynx -source $V_URL | grep -i '<title>' | sed 's#^.\+<title>.\+| \(.\+\) | Flickr.\+#\1#' | tr '/|:' '-')
	echo "  Titulo: $V_TITLE"

	V_ORIGINAL_FILE_URL=$(lynx -dump -listonly $V_URL | grep '.staticflickr' | sed 's#^.\+\(http://\)#\1#')
	echo "  URL da foto: $V_ORIGINAL_FILE_URL"

	if [ -z "$V_ORIGINAL_FILE_URL" ] ; then
		echo "  Foto nao encontrada, abrindo a URL original: $V_URL"
		xdg-open "$V_URL"
	fi

	V_EXTENSION="${V_ORIGINAL_FILE_URL##*.}"
	V_DOWNLOADED_FILE="$V_TITLE.$V_EXTENSION"
	if [ -f "$V_DIR/$V_DOWNLOADED_FILE" ] ; then
		echo "  Arquivo ja existe em: $V_DIR/$V_DOWNLOADED_FILE"
	else
		wget -O "$V_DOWNLOADED_FILE" $V_ORIGINAL_FILE_URL
		echo "  Baixada em: $V_DIR/$V_DOWNLOADED_FILE"
	fi
done
