#!/bin/bash
V_FIND="$*"
find /media/black-samsung-1tb/.audio/music -iwholename "*${V_FIND}*"
