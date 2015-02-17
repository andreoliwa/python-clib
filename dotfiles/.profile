#!/bin/bash
function _bash_utils_git_parse_branch {
	# http://www.jonmaddox.com/2008/03/13/show-your-git-branch-name-in-your-prompt/
	echo $(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
}

function _bash_utils_git_titlebar {
	if [ -n "$(_bash_utils_git_parse_branch)" ] ; then
		echo git $(basename "$PWD") $(_bash_utils_git_parse_branch)
	else
		echo "${PWD}"
	fi
}

github_create_pullrequest() {
    if [ -n "$1" ]
    then
        git branch > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            REPO=`git config --get remote.origin.url`
            if [[ "$REPO" =~ "github.com" ]]
            then
                OWNER=`echo $REPO | sed s/git@github.com://g | sed 's/\/.*//g'`
                BRANCH=`git branch | sed -n '/\* /s///p'`
                echo "hub pull-request -i $1 -b $OWNER:develop -h $OWNER:$BRANCH"
                hub pull-request -i $1 -b $OWNER:develop -h $OWNER:$BRANCH
            else
                echo "This is not a GitHub repo"
            fi
        else
            echo "You are not under a git repo"
        fi
    else
        echo "You have to provide one parameter with the issue number"
    fi
}

alias pq="github_create_pullrequest"
alias composer='php /Users/Wagner/composer.phar'
alias ll='ls -l'
alias la='ls -la'
alias gp='git pull'
alias gs='git status'
alias gb='git branch'

export COLOR_BLUE="\[\033[0;34m\]"
export COLOR_CYAN="\[\033[0;36m\]"
export COLOR_GRAY="\[\033[1;30m\]"
export COLOR_GREEN="\[\033[0;32m\]"
export COLOR_LIGHT_BLUE="\[\033[1;34m\]"
export COLOR_LIGHT_CYAN="\[\033[1;36m\]"
export COLOR_LIGHT_GRAY="\[\033[0;37m\]"
export COLOR_LIGHT_GREEN="\[\033[1;32m\]"
export COLOR_LIGHT_RED="\[\033[1;31m\]"
export COLOR_NONE="\[\033[0m\]"
export COLOR_RED="\[\033[0;31m\]"
export COLOR_WHITE="\[\033[1;37m\]"

PS1="${COLOR_LIGHT_GREEN}${TITLEBAR}\w${COLOR_GREEN}:\$(_bash_utils_git_parse_branch)${COLOR_LIGHT_GREEN}\$${COLOR_NONE} "

export VIRTUALENVWRAPPER_PYTHON=$(type -p python3)
# http://www.marinamele.com/2014/07/install-python3-on-mac-os-x-and-use-virtualenv-and-virtualenvwrapper.html
export WORKON_HOME=~/.virtualenvs
mkdir -p $WORKON_HOME
# http://jamie.curle.io/blog/installing-pip-virtualenv-and-virtualenvwrapper-on-os-x/
source /usr/local/bin/virtualenvwrapper.sh

# http://hmarr.com/2010/jan/19/making-virtualenv-play-nice-with-git/

# Automatically activate Git projects' virtual environments based on the
# directory name of the project. Virtual environment name can be overridden
# by placing a .venv file in the project root with a virtualenv name in it
function workon_cwd {
    # Check that this is a Git repo
    GIT_DIR=`git rev-parse --git-dir 2> /dev/null`
    if [[ $? == 0 ]]
    then
        # Find the repo root and check for virtualenv name override
        GIT_DIR=`\cd $GIT_DIR; pwd`
        PROJECT_ROOT=`dirname "$GIT_DIR"`
        ENV_NAME=`basename "$PROJECT_ROOT"`
        if [ -f "$PROJECT_ROOT/.venv" ]; then
            ENV_NAME=`cat "$PROJECT_ROOT/.venv"`
        fi
        # Activate the environment only if it is not already active
        if [ "$VIRTUAL_ENV" != "$WORKON_HOME/$ENV_NAME" ]; then
            if [ -e "$WORKON_HOME/$ENV_NAME/bin/activate" ]; then
                workon "$ENV_NAME" && export CD_VIRTUAL_ENV="$ENV_NAME"
            fi
        fi
    elif [ $CD_VIRTUAL_ENV ]; then
        # We've just left the repo, deactivate the environment
        # Note: this only happens if the virtualenv was activated automatically
        deactivate && unset CD_VIRTUAL_ENV
    fi
}

# New cd function that does the virtualenv magic
function venv_cd {
    builtin cd "$@" && workon_cwd
}

alias cd="venv_cd"

PATH=${PATH}:~/bin
export PATH

# https://docs.docker.com/installation/mac/
$(boot2docker shellinit)

# https://www.jetbrains.com/pycharm/webhelp/remote-debugging.html#1
export PYTHONPATH=/Applications/PyCharm.app/Contents/pycharm-debug.egg

# cd ~/eatfirst/cave/
