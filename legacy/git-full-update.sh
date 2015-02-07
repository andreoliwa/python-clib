#!/bin/bash
V_ALL_REPOS=$(find $G_WORK_SRC_DIR -type d -name .git | sed 's#/.git##' | sort)

for V_REPO in $V_ALL_REPOS ; do
	echo
	echo "Repositorio Git $V_REPO"
	cd $V_REPO

	git update
	if [ $? != 0 ] ; then
		git stash
		git up
		git stash pop
	fi
done
publish.sh

for V_REPO in $V_ALL_REPOS ; do
	echo
	echo "Repositorio Git $V_REPO"
	cd $V_REPO
	git bs
done

# Shows the current date
echo -e "\nLast execution: $(date --rfc-3339=seconds)"
