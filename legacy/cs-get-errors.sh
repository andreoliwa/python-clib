#!/bin/bash
cat $1 | grep -e '$error' -e '^class ' | sed -e "s/^.\+error \+= \+'\([^']\+\)'.\+$/<message>\1/" -e "s/^.\+->add\(Error\|Warning\).\+'\([^']\+\)'.\+$/.\2/" | awk '/^class / { V_RULE = $2 ; sub( /_Sniffs/ , "" , V_RULE ) ; sub( /Sniff$/ , "" , V_RULE ) ; gsub( "_" , "." , V_RULE ) }
/<message>/ { V_MESSAGE = $0 "</message>" }
/^\./ {print "<rule ref=\"" V_RULE $0 "\">\n\t" V_MESSAGE "\n</rule>" }'
