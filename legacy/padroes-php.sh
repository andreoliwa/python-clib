#!/bin/bash
if [ $HOSTNAME = $G_WORK_COMPUTER ] ; then
	V_DIR=/net/srvfol1/groups/desenvolvimento
else
	V_DIR=/folha/src/home-office/code-sniffer
fi

V_LIST_PDF="ls $V_DIR/*.pdf"
$V_LIST_PDF
evince "$($V_LIST_PDF)"
