#!/bin/bash

RUNNING=$(ps aux | grep -v grep | grep "type='signal',interface='org.gnome.ScreenSaver'")

# This line monitors screen lock and unlock, and appends the current date to the log
if [ -z "$RUNNING" ] ; then
	echo "Iniciando monitoramento de lock/unlock da tela"
	dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" | ( while true; do read X; if echo $X | grep "boolean true" &> /dev/null; then echo "$(date "+%Y-%m-%d %k:%M"): Autolock: Trabalhando" >> ~/.gtimelog/timelog.txt; elif echo $X | grep "boolean false" &> /dev/null; then echo "$(date "+%Y-%m-%d %k:%M"): Autolock: Fora da mesa **" >> ~/.gtimelog/timelog.txt; fi done ) &
else
	echo 'Script ja executando:'
fi

ps aux | grep -v -e grep -e $$ | grep --color=auto -e dbus-monitor -e $(basename $0)
