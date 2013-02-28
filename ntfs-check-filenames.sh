#!/bin/bash
V_START_DIR="$1"
[ -z "$V_START_DIR" ] && V_START_DIR="$PWD"

echo "Checking NTFS filenames in directory $V_START_DIR"
echo "Directories endind with spaces or points:"
find $V_START_DIR -type d -regex '.+[ \.]$' -exec xdg-open '{}' \;
