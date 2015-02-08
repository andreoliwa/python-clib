#!/bin/bash

# Se nenhum argumento for informado, procura tambem @todo; caso contrario, procura somente o resto dos padroes
TODO_PATTERN=''
[ -z "$1" ] && TODO_PATTERN='-e @todo'

# Procura coisas pendentes a fazer no código
V_PATTERNS_FILE=$HOME/bin/git-todo-patterns.txt
git no | xargs grep -i $TODO_PATTERN --color=auto -f $V_PATTERNS_FILE 2> /dev/null | sed 's/[ \t]\+/ /g' | grep -i $TODO_PATTERN --color=auto -f $V_PATTERNS_FILE
