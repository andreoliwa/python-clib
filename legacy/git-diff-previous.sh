#!/bin/bash
V_ARGS="$*"
git diff $(git log | grep 'commit ' | sed 's/commit //' | sed -n 2p) $V_ARGS
