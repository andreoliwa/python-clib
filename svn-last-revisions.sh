#!/bin/bash
V_HOW_MANY="$1"
[ -z "$V_HOW_MANY" ] && V_HOW_MANY=20

# Revisions from the last 3 days
echo "dev_bin"
svn log $G_SVN_URL/dev_bin -q -rHEAD:{$(date --date="3 days ago" +%F)} | grep -v -e '----------' | head -n $V_HOW_MANY | cut -b 2-
echo "dev_htdocs"
svn log $G_SVN_URL/dev_htdocs -q -rHEAD:{$(date --date="3 days ago" +%F)} | grep -v -e '----------' | head -n $V_HOW_MANY | cut -b 2-
