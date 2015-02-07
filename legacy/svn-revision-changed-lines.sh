#!/bin/bash
V_REVISION=666
V_REPO="dev_repo"
V_FILE="/path/to/file"
V_SVN_URL="$G_SVN_URL/${V_REPO}${V_FILE}@${V_REVISION}"
echo "$V_SVN_URL"
svn blame "$V_SVN_URL" | sed 's/^ \+//' | cut -d ' ' -f 1 | awk '{print NR"="$0}' | grep '='$V_REVISION | sed 's/='${V_REVISION}'//'
