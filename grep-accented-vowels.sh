#!/bin/bash
export LC_ALL=C
grep --color=always -i -e "[^ -~a-zA-Z0-9<>=|	]\+" "$*"
#grep --color=always -i -e '[αινσϊΰγυβκτ]\+' $*
# echo 'Letters:'
# grep --color=always -oi -e '[αινσϊΰγυβκτ]\+' $* | sort -u
