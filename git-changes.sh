#!/bin/bash
V_COMMIT_ID=$1

# Se nenhum commit foi informado, pega o mais recente
if [ -z "$V_COMMIT_ID" ] ; then
	V_COMMIT_ID=$(git log -1 --format=format:%H)
fi

git log $V_COMMIT_ID -1 --name-status
git diff "$V_COMMIT_ID~1..$V_COMMIT_ID"
