#!/bin/bash
echo '>>> Pull'
git checkout master
[ $? = 0 ] && git pull

echo '>>> Remote prune'
git remote prune origin

echo '>>> Fetch prune'
git fetch origin --prune

echo '>>> Clear branches'
git-clear-local-branches.sh

echo '>>> GC'
git gc --prune=now
