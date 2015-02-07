#!/bin/bash
V_SECONDS="$*"
[ -z "$V_SECONDS" ] && V_SECONDS=45
echo "Sleeping $V_SECONDS seconds"
sleep $V_SECONDS

# Second monitor becomes primary
xrandr --output VGA1 --primary
