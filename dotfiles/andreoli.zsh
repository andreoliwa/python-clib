alias hi='hub pull-request -i'
alias glm='git log ...master'
alias gld='git log ...develop'
alias grepalias='alias | grep '
alias gdm='git diff master'
alias gdd='git diff develop'

if [[ "${OSTYPE//[0-9.]/}" == 'darwin' ]]; then
    cd ~/eatfirst/cave
fi
