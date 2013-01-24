#!/bin/bash
cd $G_DOWNLOAD_DIR

for V_OFX_FILE in $(find *.ofx 2> /dev/null) ; do
	echo
	echo "File: $V_OFX_FILE"

	V_ACCOUNT_NUMBER=$(cat $V_OFX_FILE | grep ACCTID | sed 's/[^0-9]//g')
	echo "Account number: ${V_ACCOUNT_NUMBER}"
	V_ACCOUNT_NAME=unknown
	if [ "$V_ACCOUNT_NUMBER" = "$G_PERSONAL_BANK_ACCOUNT" ] ; then
		V_ACCOUNT_NAME=juridica
	fi
	if [ "$V_ACCOUNT_NUMBER" = "$G_WORK_BANK_ACCOUNT" ] ; then
		V_ACCOUNT_NAME=fisica
	fi

	V_DATE_TIME=$(stat -c %y $V_OFX_FILE | cut -b 1-19 | tr ' :' '_-')
	echo "Date/time: $V_DATE_TIME"

	V_NEW_DIR=$G_BANK_STATEMENTS_DIR/$V_ACCOUNT_NAME
	mkdir -p "$V_NEW_DIR"
	V_NEW_FILE="$V_NEW_DIR/$V_ACCOUNT_NAME-$V_DATE_TIME.ofx"
	echo "New file: $V_NEW_FILE"

	mv -v "$V_OFX_FILE" "$V_NEW_FILE"
done

V_PDF_FILES=$(ls *.pdf 2> /dev/null)
if [ -n "$V_PDF_FILES" ] ; then
	nautilus $G_DOWNLOAD_DIR
	nautilus $G_BANK_STATEMENTS_DIR
fi
