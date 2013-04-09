#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [-tdgrh]
Show total working hours at home office.

-t  Total de horas
-d  Relatorio detalhado para Adm TI
-g  Faz grep no log do Git, trazendo so o que foi escolhido aqui
-r  Gera um mini-relatorio em um .txt
-n  Dry-run, não muda a data do último relatório no arquivo
-l  Mostra a data de geração do último relatório
-h  Help"
	exit $1
}

V_TOTAL=
V_DETAIL=
V_GREP=
V_REPORT=
V_DRY_RUN=
V_SHOW_LAST_REPORT=
while getopts "tdg:rnlh" V_ARG ; do
	case $V_ARG in
		t)	V_TOTAL=1 ;;
		d)	V_DETAIL=1 ;;
		g)	V_GREP="$V_GREP --grep=$OPTARG" ;;
		r)	V_REPORT=1 ;;
		n)	V_DRY_RUN=1 ;;
		l)	V_SHOW_LAST_REPORT=1 ;;
		h)	usage 1 ;;
		?)	usage 1 ;;
	esac
done

V_LAST_REPORT_FILE=$HOME/bin/git-last-report.txt
V_LAST_REPORT_DATE="$(cat $V_LAST_REPORT_FILE 2>/dev/null)"
V_AFTER=
[ -n "$V_LAST_REPORT_DATE" ] && V_AFTER="--after=$V_LAST_REPORT_DATE"

if [ -n "$V_SHOW_LAST_REPORT" ] ; then
	echo "Data do último relatório: $(cat $V_LAST_REPORT_FILE) (arquivo $V_LAST_REPORT_FILE)"
	exit
fi

cd $G_DROPBOX_DIR/src/home-office/

if [ -n "$V_REPORT" ] ; then
	V_REPORT_FILE="$G_DOWNLOAD_DIR/wagner-home-office-$(date --rfc-3339=date).txt"
	rm $V_REPORT_FILE > /dev/null
	echo "Total de horas do último relatório ($V_LAST_REPORT_DATE) até hoje $(date '+%d/%m/%Y'):"
	V_TOTAL=1
	echo "Gabriela, bom dia,

Pode incluir estes horários no ImHere?

$($(basename $0) -d)

Obrigado!

===

Ari, este trabalho remoto é referente a estas tarefas:

$(git log --reverse  --after=2012-09-14 | grep -io '@task.\+' | sed 's#\(@task \)\([0-9]\+\)\(.\+\)$#\1\2\3\nhttp://webmaster.corp.folha.com.br/admin/snitch/index/tarefa/modificar?idx=\2\n#')

--
[]s
Wagner Andreoli
Desenvolvedor - TI Folha de S.Paulo" >> $V_REPORT_FILE

	subl $V_LAST_REPORT_FILE $V_REPORT_FILE &

	thunderbird -compose "to='l-tec-admti@grupofolha.com.br',cc='ariovaldo.carmona@grupofolha.com.br',subject='[ImHere] Horas extras de trabalho remoto',body='$(cat $V_REPORT_FILE)'"

	if [ -z "$V_DRY_RUN" ] ; then
		# Grava a data atual como sendo a data do ultimo relatorio gerado
		echo "$(date --rfc-3339=date)" > $V_LAST_REPORT_FILE
	fi
fi

if [ -z "$V_TOTAL" ] && [ -z "$V_DETAIL" ] ; then
	echo 'Escolha pelo menos um: -t ou -d'
	usage
	exit
fi

if [ -n "$V_TOTAL" ] ; then
	git log $V_AFTER $V_GREP --reverse --format=short | grep -i 'trabalho remoto' | sed 's/^.\+trabalho remoto.*: .*(\(..:..\) horas).*$/\1/i' | sum-hours.sh
fi

if [ -n "$V_DETAIL" ] ; then
	V_OLD_IFS=$IFS
	IFS='
'
	V_TMP_FILE=/tmp/$(basename $0).tmp
	rm $V_TMP_FILE 2> /dev/null
	touch $V_TMP_FILE

	for V_LINE in $(eval "git log $V_AFTER $V_GREP --reverse --format=short" | grep -io 'trabalho remoto.*') ; do
		V_DATE=$(echo $V_LINE | awk '{ print $3 }')

		V_NEW_DATE=
		case $V_DATE in
		2012-06-06)
			V_NEW_DATE=2012-07-10 ;;
		2012-06-09)
			V_NEW_DATE=2012-07-07 ;;
		2012-06-11)
			V_NEW_DATE=2012-07-12 ;;
		2012-06-13)
			V_NEW_DATE=2012-07-20 ;;
		2012-06-14)
			V_NEW_DATE=2012-07-19 ;;
		2012-06-23)
			V_NEW_DATE=2012-07-21 ;;
		2012-06-25)
			V_NEW_DATE=2012-07-25 ;;
		2012-06-26)
			V_NEW_DATE=2012-07-26 ;;
		2012-06-27)
			V_NEW_DATE=2012-07-27 ;;
		2012-06-28)
			V_NEW_DATE=2012-07-30 ;;
		2012-06-29)
			V_NEW_DATE=2012-07-31 ;;
		2012-06-30)
			V_NEW_DATE=2012-07-28 ;;
		2012-07-02)
			V_NEW_DATE=2012-07-09 ;;
		esac
		#if [ -z "$V_NEW_DATE" ] && [[ $V_DATE == *-06-* ]] ; then
		#	V_NEW_DATE=$(echo $V_DATE | sed 's/-06-/-07-/')
		#fi

		V_CHANGED=
		if [ -n "$V_NEW_DATE" ] ; then
			V_CHANGED=' *'
			V_LINE=$(echo "${V_LINE}" | sed "s/$V_DATE/$V_NEW_DATE/")
			V_DATE="$V_NEW_DATE"
		fi

		V_WEEKDAY_NAME=$(weekday-name.sh -d $V_DATE)
		V_RESULT_LINE=$(echo "${V_LINE}${V_CHANGED}" | sed "s#\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)#$V_WEEKDAY_NAME \3/\2/\1#")
		echo "$V_DATE$V_RESULT_LINE" >> $V_TMP_FILE
	done
	IFS=$V_OLD_IFS

	cat $V_TMP_FILE | sort | cut -b 11-
fi
