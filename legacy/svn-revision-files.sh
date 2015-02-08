#!/bin/bash
V_REPO="$1"
V_REVISION="$2"

if [ "$V_REPO" = 'h' -o "$V_REPO" = 'htdocs' ] ; then
	V_REPO=dev_htdocs
fi
if [ "$V_REPO" = 'b' -o "$V_REPO" = 'bin' ] ; then
	V_REPO=dev_bin
fi

# Show modified files in a revision
svn log $G_SVN_URL/$V_REPO -r $V_REVISION -qv | awk '/\//{print $1 $2}'
