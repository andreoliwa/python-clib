alias hi='hub pull-request -i'
alias glm='git log ...master'
alias gld='git log ...develop'
alias grepalias='alias | grep '
alias gdm='git diff master'
alias gdd='git diff develop'
alias gstl='git stash list'

export PROJECT_HOME=~/Dropbox/src/python

if [[ "${OSTYPE//[0-9.]/}" == 'darwin' ]]; then
	alias gwip='git add -A; git ls-files --deleted -z | xargs git rm; git commit -m "--wip--"'
    cd ~/eatfirst/cave
fi
