#!/bin/bash
_git_exec_command() {
    V_COMMAND=$1
    echo
    echo '$ '$V_COMMAND
    eval $V_COMMAND
}

V_CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

_git_exec_command 'git checkout master'
if [ $? = 0 ]; then
    _git_exec_command 'git pull'
fi

_git_exec_command 'git remote prune origin'
_git_exec_command 'git fetch origin --prune'
_git_exec_command 'git-clear-local-branches.sh'
_git_exec_command 'git gc --prune=now'

if [[ "$V_CURRENT_BRANCH" != 'master' ]]; then
	_git_exec_command 'git checkout '$V_CURRENT_BRANCH
fi
