#!/bin/bash
cd $G_DOWNLOAD_DIR

mv_ofx() {
	V_OLD_IFS=$IFS
	IFS='
'
	for V_OFX_FILE in $(find $G_DOWNLOAD_DIR -iname '*.ofx') ; do
		echo
		echo "File: $V_OFX_FILE"

		V_ACCOUNT_NUMBER=$(cat "$V_OFX_FILE" | grep ACCTID | sed 's/[^0-9]//g')
		echo "Account number: ${V_ACCOUNT_NUMBER}"

		V_ACCOUNT_NAME=unknown
		if [ "$V_ACCOUNT_NUMBER" = "$G_PERSONAL_BANK_ACCOUNT" ] ; then
			V_ACCOUNT_NAME=juridica
		fi
		if [ "$V_ACCOUNT_NUMBER" = "$G_WORK_BANK_ACCOUNT" ] ; then
			V_ACCOUNT_NAME=fisica
		fi

		V_DATE_TIME=$(stat -c %y "$V_OFX_FILE" | cut -b 1-19 | tr ' :' '_-')

		V_NEW_DIR=$G_BANK_STATEMENTS_DIR/buxfer/new
		mkdir -p "$V_NEW_DIR"
		V_NEW_FILE="$V_NEW_DIR/$V_ACCOUNT_NAME-$V_DATE_TIME.ofx"
		echo "New file: $V_NEW_FILE"

		mv -v "$V_OFX_FILE" "$V_NEW_FILE"
	done
	IFS=$V_OLD_IFS
}

mv_torrent() {
	[ "$(ls -1 *.torrent 2>/dev/null | wc -l)" -gt 0 ] && mv -v *.torrent $G_DROPBOX_DIR/torrent/
}

has_pdf() {
	if [ "$(ls -1 *.pdf* 2>/dev/null | wc -l)" -gt 0 ] ; then
		xdg-open $G_DOWNLOAD_DIR
		xdg-open $G_BANK_STATEMENTS_DIR
	fi
}

mv_ofx
mv_torrent
has_pdf

echo "Contents of $PWD:"
ls -l
