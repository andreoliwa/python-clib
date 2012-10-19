#!/bin/bash
LANGUAGE=$1
[ -z "$LANGUAGE" ] && LANGUAGE=" "
find . -iregex '.+\.\(mp4\|avi\|divx\)' -exec video-show-if-missing-subtitle.sh "$LANGUAGE" '{}' \; | sort
