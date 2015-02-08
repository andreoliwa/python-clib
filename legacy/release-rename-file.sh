#!/bin/bash

OLD_IFS=$IFS
IFS="
"
for V_FULL_PATH in $(cat) ; do
	V_DIR=$(dirname $V_FULL_PATH)
	V_BASE=$(basename $V_FULL_PATH)
	V_NEW_NAME="$V_DIR/$(release-name.sh $V_BASE)"

	if [ "$V_FULL_PATH" != "$V_NEW_NAME" ] ; then
		mv -v "$V_FULL_PATH" "$V_NEW_NAME"
	fi
done
IFS=$OLD_IFS
