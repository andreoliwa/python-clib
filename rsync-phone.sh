#!/bin/bash
ARGS="$*"
if [ -n "$ARGS" ] ; then
	echo "Arguments: <$ARGS>"
fi

SOURCE_DIR='$G_EXTERNAL_HDD/.audio/music/in/phone/'
DESTINATION_DIR='/media/MOTO DEFY/Music/phone/'
[ ! -d $SOURCE_DIR ] &&	echo "Source directory not found: $SOURCE_DIR" && exit
[ ! -d "$DESTINATION_DIR" ] && echo "Destination directory not found: $DESTINATION_DIR" && exit
rmdir-empty.sh $SOURCE_DIR
for PASS in {1..2} ; do
	echo "rsync $SOURCE_DIR -> $DESTINATION_DIR (pass $PASS)"
	rsync $ARGS -hvuzr --links --delete-during --modify-window=2 --omit-dir-times --progress $SOURCE_DIR "$DESTINATION_DIR"
done
ntfs-check-filenames.sh $SOURCE_DIR

echo "Nao copia diretorio unknown ainda..."
exit

SOURCE_DIR='$G_EXTERNAL_HDD/.audio/music/unknown/'
DESTINATION_DIR='/media/MOTO DEFY/Music/unknown/'
#@todo Nao fazer copy/paste
[ ! -d $SOURCE_DIR ] &&	echo "Source directory not found: $SOURCE_DIR" && exit
[ ! -d "$DESTINATION_DIR" ] && echo "Destination directory not found: $DESTINATION_DIR" && exit
rmdir-empty.sh $SOURCE_DIR
for PASS in {1..2} ; do
	echo "rsync $SOURCE_DIR -> $DESTINATION_DIR (pass $PASS)"
	rsync $ARGS -hvuzr --links --delete-during --modify-window=2 --omit-dir-times --progress $SOURCE_DIR "$DESTINATION_DIR"
done
ntfs-check-filenames.sh $SOURCE_DIR
