alias hi='hub pull-request -i'
alias glm='git log ...master'
alias gld='git log ...develop'
alias grepalias='alias | grep '
alias gdm='git diff master'
alias gdd='git diff develop'
alias gstl='git stash list'

if [[ "${OSTYPE//[0-9.]/}" == 'darwin' ]]; then
    cd ~/eatfirst/cave
fi
