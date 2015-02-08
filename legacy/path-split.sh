#!/bin/bash
V_PATH=common/includes/hast/importer/abc
echo $V_PATH '-----' $(expr match "$V_PATH" '\([^/]\+/[^/]\+\)') '-----' ${V_PATH#*/*/}

cd ~/.config/gnome-control-center/backgrounds
V_PATH=${PWD:1}
echo $V_PATH '-----' $(expr match "$V_PATH" '\([^/]\+/[^/]\+\)') '-----' ${V_PATH#*/*/}
