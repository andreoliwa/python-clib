#!/usr/bin/env bash

for flashpid in $(pgrep -f flashplayer.so); do
    cd "/proc/$flashpid/fd"
    for video in $(file * | grep '/tmp/Flash' | sed 's/\(^[0-9]*\).*/\1/g'); do
        echo "/proc/$flashpid/fd/$video"
        #cp -f -v "/proc/$flashpid/fd/$video" $G_DOWNLOAD_DIR/$video.flv
    done
done

ls -l $G_DOWNLOAD_DIR/*.flv
#vlc $G_DOWNLOAD_DIR/*.flv
