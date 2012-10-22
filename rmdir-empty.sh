#!/bin/bash
V_START_FROM="."
[ -n "$1" ] && V_START_FROM="$1"

echo "Removing empty directories under $V_START_FROM following symbolic links"
find -H $V_START_FROM -depth -type d -empty -exec rmdir -v '{}' \;
