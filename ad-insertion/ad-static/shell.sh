#!/bin/bash -e

IMAGE="ssai_ad_insertion_ad_static"
DIR=$(dirname $(readlink -f "$0"))
OPTIONS=("--volume=$DIR/../../volume/ad/static:/mnt:rw" "--volume=$DIR:/home:ro" "--volume=$DIR/../../volume/ad/demo:/demo:rw" "--volume=$DIR/../../volume/ad/archive:/archive:rw")

. "$DIR/../../script/shell.sh"
