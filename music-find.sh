#!/bin/bash
V_FIND="$*"
find $G_EXTERNAL_HDD/.audio/music -iwholename "*${V_FIND}*"
