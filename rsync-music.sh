#!/bin/bash
INVERT=$1
ARGS="$2 $3 $4 $5 $6 $7 $8 $9"
if [ -n "$ARGS" ] ; then
	echo "Argumentos: $ARGS"
fi

SOURCE_DIR=$G_EXTERNAL_HDD/audio/music/
DESTINATION_DIR=/home/music/
if [ "$INVERT" = "-i" -o "$INVERT" = "--invert" -o "$INVERT" = "inv" ] ; then
	echo "rsync invertido, trocando diretorios"
	SWAP=$SOURCE_DIR
	SOURCE_DIR=$DESTINATION_DIR
	DESTINATION_DIR=$SWAP
fi

if [ ! -d $SOURCE_DIR ] ; then
	echo "Diretorio origem nao encontrado: $SOURCE_DIR"
	exit
fi
if [ ! -d $DESTINATION_DIR ] ; then
	echo "Diretorio destino nao encontrado: $DESTINATION_DIR"
	exit
fi

rmdir-empty.sh $SOURCE_DIR

for PASS in {1..2} ; do
	echo "rsync $SOURCE_DIR -> $DESTINATION_DIR (pass $PASS)"
	V_COMMAND="rsync $ARGS -hvuzr --links --delete-during --modify-window=2 --omit-dir-times --progress --exclude=*.wav --exclude=out/ --exclude=temp_* $SOURCE_DIR $DESTINATION_DIR"
	echo "$V_COMMAND"
	$V_COMMAND
done

ntfs-check-filenames.sh $SOURCE_DIR
