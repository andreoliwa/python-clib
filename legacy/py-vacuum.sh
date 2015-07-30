#!/bin/bash
find . -iname '*.pyc' -delete 2>/dev/null
find . -iname __pycache__ -exec rm -rf $* '{}' \; 2>/dev/null
# rm -rf $* build
