#!/bin/bash
V_NUMBER=$1
git branch --all --list *$V_NUMBER* | sed 's#remotes/origin/##' | cut -b 3- | head -1 | xargs git co
git status
