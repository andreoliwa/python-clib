#!/bin/bash
# http://stackoverflow.com/questions/7726949/remove-branches-not-longer-on-remote

_git_remove_unused_branches() {
    V_BASE_BRANCH=$1

    git checkout $V_BASE_BRANCH &&
    for V_REF in $(git for-each-ref refs/heads --format='%(refname:short)')
    do
        if [ x$(git merge-base $V_BASE_BRANCH "$V_REF") = x$(git rev-parse --verify "$V_REF") ]
        then
            if [ "$V_REF" != "$V_BASE_BRANCH" -a "$V_REF" != "master" -a "$V_REF" != "develop" ]
            then
                git branch -d "$V_REF"
            fi
        fi
    done
}

_git_remove_unused_branches master
