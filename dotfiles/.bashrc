#!/bin/bash
V_INSIDE_VIRTUAL_MACHINE=
[[ $HOSTNAME == vm*folha.com.br ]] || [ $HOSTNAME = 'honshu.folha.com.br' ] && V_INSIDE_VIRTUAL_MACHINE=1

function _bash_utils_git_parse_branch {
	# http://www.jonmaddox.com/2008/03/13/show-your-git-branch-name-in-your-prompt/
	echo $(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/')
}

function _bash_utils_git_titlebar {
	if [ -n "$(_bash_utils_git_parse_branch)" ] ; then
		echo git $(basename "$PWD") $(_bash_utils_git_parse_branch)
	else
		echo "${PWD}"
	fi
}

# Replaces the built-in command "cd", saving the last used directory
# This will be useful in a remote machine, if you want to restore the last working directory on login
# Got the idea from http://ss64.com/bash/builtin.html
function cd() {
	builtin cd "$@" && echo "$PWD" > ~/.last-pwd
}

# My personal environment variables
[ -f ~/bin/.clitoolkitrc ] && . ~/bin/.clitoolkitrc

if [ -n "$V_INSIDE_VIRTUAL_MACHINE" ] ; then
	# The colors seem to be different to CentOS
	# I had to define them this way, otherwise the prompt flickers inside the VMs, and the Bash reverse search doesn't work
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
else
	# Ubuntu colors
	export COLOR_BLUE='\e[0;34m'
	export COLOR_CYAN='\e[0;36m'
	export COLOR_GRAY='\e[1;30m'
	export COLOR_GREEN='\e[0;32m'
	export COLOR_LIGHT_BLUE='\e[1;34m'
	export COLOR_LIGHT_CYAN='\e[1;36m'
	export COLOR_LIGHT_GRAY='\e[0;37m'
	export COLOR_LIGHT_GREEN='\e[1;32m'
	export COLOR_LIGHT_RED='\e[1;31m'
	export COLOR_NONE='\e[0m'
	export COLOR_RED='\e[0;31m'
	export COLOR_WHITE='\e[1;37m'
fi

function prompt_elite {
	case $TERM in
	    xterm*|rxvt*)
	        local TITLEBAR='\[\033]0;\u@\h:\w\007\]'
	        ;;
	    *)
	        local TITLEBAR=""
	        ;;
	esac

	local temp=$(tty)
	local GRAD1=${temp:5}
	PS1="$TITLEBAR\
$COLOR_GRAY-$COLOR_CYAN-$COLOR_LIGHT_CYAN(\
$COLOR_CYAN\u$COLOR_GRAY@$COLOR_CYAN\h\
$COLOR_LIGHT_CYAN)$COLOR_CYAN-$COLOR_LIGHT_CYAN(\
$COLOR_CYAN\#$COLOR_GRAY/$COLOR_CYAN$GRAD1\
$COLOR_LIGHT_CYAN)$COLOR_CYAN-$COLOR_LIGHT_CYAN(\
$COLOR_CYAN\$(date +%H%M)$COLOR_GRAY/$COLOR_CYAN\$(date +%d-%b-%y)\
$COLOR_LIGHT_CYAN)$COLOR_CYAN-$COLOR_GRAY-\
$COLOR_LIGHT_GRAY\n\
$COLOR_GRAY-$COLOR_CYAN-$COLOR_LIGHT_CYAN(\
$COLOR_CYAN\$$COLOR_GRAY:$COLOR_CYAN\w\
$COLOR_LIGHT_CYAN)$COLOR_CYAN-$COLOR_GRAY-$COLOR_LIGHT_GRAY "
	PS2="$COLOR_LIGHT_CYAN-$COLOR_CYAN-$COLOR_GRAY-$COLOR_NONE "
}

function _bash_utils_git_prompt {
	case $TERM in
	xterm*)
		TITLEBAR='\[\033]0;$(_bash_utils_git_titlebar)\007\]'
	;;
	*)
		TITLEBAR=""
	;;
	esac

	PS1="${TITLEBAR}${debian_chroot:+($debian_chroot)}${COLOR_LIGHT_GREEN}\u@\h${COLOR_LIGHT_BLUE} \w $COLOR_LIGHT_RED\$(_bash_utils_git_parse_branch)$COLOR_LIGHT_BLUE\n\$\[\033[00m\] "
	PS2='> '
	PS4='+ '
}

# Special treatment for work virtual machines
if [ -n "$V_INSIDE_VIRTUAL_MACHINE" ] ; then
	# Source global definitions
	if [ -f /etc/bashrc ]; then
		. /etc/bashrc
	fi

	TITLEBAR='\[\e]0;\h:${PWD}\a\]'

	# Development VM is green; production VMs are red
	if [[ ($HOSTNAME == vm206*folha.com.br) || ($HOSTNAME == vm217*folha.com.br) || ($HOSTNAME == vm220*folha.com.br) || ($HOSTNAME == vm226*folha.com.br) ]] ; then
		PS1="${COLOR_LIGHT_GREEN}${TITLEBAR}\u@\h:\W\$${COLOR_NONE} "
	else
		PS1="${COLOR_LIGHT_RED}${TITLEBAR}\u@\h:\W\$${COLOR_NONE} "
	fi

	export GREP_OPTIONS='--exclude=\*.svn\*'
	export MY_LOG_DIRECTORY='/net/odyssey/local/dev_desenvolvedores/19/log/repulse'

	# Safe file deletion for CentOS
	alias rm='rm -i'
else
	_bash_utils_git_prompt

	# Safe file deletion for Ubuntu
	alias rm='rm -Iv'
fi

# User specific aliases and functions
alias la='ls -lah'
alias ll='ls -lh'
alias lr='ls -larh'
alias ls='ls --color=auto'
alias lt='ls -lht'
alias top='top -d 1 -c'
alias grep='grep --color=auto'
alias psgrep='ps aux | grep -v grep | grep -e '^USER' -e '
alias pwd='pwd;pwd -P'
alias t='tmux-open.sh -s'
alias git=hub
alias pf='pip freeze'
alias gs='git status'
alias gb='git branch'
alias gd='git diff'

export HISTCONTROL=ignoreboth:ignoCOLOR_redups:erasedups
export HISTSIZE=50000
shopt -s histappend

# Prompt for the MySQL command line client
export MYSQL_PS1="(\u@\h) \d>\_"

if [ -n "$V_INSIDE_VIRTUAL_MACHINE" ] ; then
	exit
fi

# Enables the CONTROL+S shortcut to move forward in an incremental search started with CONTROL+R
stty -ixon

# Set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
	# Adding global Composer dir to the PATH, according to http://akrabat.com/php/global-installation-of-php-tools-with-composer/
	export PATH="$HOME/bin:$G_DROPBOX_DIR/src/python/clitoolkit/legacy:$HOME/.composer/vendor/bin:$PATH"
fi

# Autocomplete for sudo?
if [ "$PS1" ] ; then
	complete -cf sudo
fi

if [ -f /etc/bash_completion ] && ! shopt -oq posix ; then
	. /etc/bash_completion
fi

# http://askubuntu.com/questions/85612/how-to-call-zenity-from-cron-script
xhost local:$(whoami) > /dev/null

### Added by the Heroku Toolbelt
export PATH="$PATH:/usr/local/heroku/bin"

# Setting a fixed browser to be used by Python's webbrowser module under Sublime Text 2
# It worked on the command line, after some research:
# https://github.com/revolunet/sublimetext-markdown-preview/issues/2#issuecomment-4221079
# http://docs.python.org/2/library/webbrowser.html#module-webbrowser
export BROWSER=/usr/bin/chromium-browser

# http://simononsoftware.com/virtualenv-tutorial-part-2/
export WORKON_HOME=$HOME/.virtualenvs
export PROJECT_HOME=$G_DROPBOX_DIR/src/python
source /usr/local/bin/virtualenvwrapper_lazy.sh

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
    # elif [ $CD_VIRTUAL_ENV ]; then
        # We've just left the repo, deactivate the environment
        # Note: this only happens if the virtualenv was activated automatically
        # deactivate && unset CD_VIRTUAL_ENV
    fi
}

# New cd function that does the virtualenv magic
function venv_cd {
    builtin cd "$@" && workon_cwd
}

alias cd="venv_cd"

# Call the function once, if you're already in a virtualenv dir (when you open a terminal from another)
cd $PWD
