#!/bin/bash
usage() {
	echo "Usage: $(basename $0) [options]
Push the changes to all remotes, not only 'origin'.

OPTIONS
-n   Dry-run
-h   Help"
	exit $1
}

V_DRY_RUN=
while getopts "nh" V_ARG ; do
	case $V_ARG in
		n)	V_DRY_RUN=-n ;;
		h)	usage 1 ;;
		?)	usage 2 ;;
	esac
done

V_DRY_RUN_STRING=
[ -n "$V_DRY_RUN" ] && V_DRY_RUN_STRING='(DRY-RUN) '

git remote -v show
echo

echo "${V_DRY_RUN_STRING}Pushing matching branches to the origin remote"
time git push $V_DRY_RUN origin :
echo

for V_OTHER_REMOTE in $(git remote show | grep -v origin) ; do
	echo "${V_DRY_RUN_STRING}Pushing changes to the $V_OTHER_REMOTE remote (master branch)"
	time git push $V_DRY_RUN $V_OTHER_REMOTE master
done
