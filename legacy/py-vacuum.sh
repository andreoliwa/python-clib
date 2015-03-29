#!/bin/bash
find . -name '*.pyc' -exec rm $* '{}' \; 2>/dev/null
find . -name __pycache__ -exec rm -rf $* '{}' \; 2>/dev/null
rm -rf $* build
