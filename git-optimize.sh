#!/bin/bash
V_ALL_REPOS="$G_WORK_SRC_DIR/dev_bin $G_WORK_SRC_DIR/dev_htdocs"
for V_REPO in $V_ALL_REPOS ; do
	echo
	echo "Repositorio Git $V_REPO"
	cd $V_REPO

	git repack -d -a && git prune-packed
done

# Faz backup dos fontes
backup-full.sh -f
