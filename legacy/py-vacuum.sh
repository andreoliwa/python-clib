#!/bin/bash
find . -name __pycache__ -exec rm -rvf '{}' \; 2>/dev/null
find . -name '*.pyc'
find . -name '*.pyc' -delete
rm -rvf build
