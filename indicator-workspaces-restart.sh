#!/bin/bash
V_PID="$(ps aux | grep -v grep | grep '/usr/bin/indicator-workspaces' | sed 's/ \+/\t/g' | cut -f 2)"
[ -n "$V_PID" ] && kill "$V_PID"
indicator-workspaces &
