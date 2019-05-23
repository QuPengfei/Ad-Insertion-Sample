#!/bin/bash -e

IMAGE="ssai_content_provider_archive"
DIR=$(dirname $(readlink -f "$0"))
clips=()

case "$(cat /proc/1/sched | head -n 1)" in
*ad_text.sh*)
    for clip in `find /bak -name "*.mp4" -print`; do
        clip_name="${clip/*\//}"
        echo $clip_name
        if test ! -f "/archive/$clip_name"; then
            ffmpeg -i "/bak/$clip_name" -vf "scale=1920:1080,drawtext=text='Server-Side AD Insertion':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=70:fontcolor=yellow@0.2" -y "/archive/$clip_name"
        fi
    done
    wait
    ;;
*) 
    mkdir -p "$DIR/../../volume/ad/archive"
    mkdir -p "$DIR/../../volume/ad/bak"
    . "$DIR/../../script/build.sh"
    . "$DIR/shell.sh" /home/ad_text.sh $@
    ;;
esac
