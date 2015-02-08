#!/bin/bash
DIR="$*"
find $DIR -type f | wc -l
