#!/bin/bash -e

DIR=$(dirname $(readlink -f "$0"))
export AD_ARCHIVE_VOLUME=$(readlink -f "$DIR/../../volume/ad/archive")
export AD_DASH_VOLUME=$(readlink -f "$DIR/../../volume/ad/dash")
export AD_HLS_VOLUME=$(readlink -f "$DIR/../../volume/ad/hls")
export AD_STATIC_VOLUME=$(readlink -f "$DIR/../../volume/ad/static")
export VIDEO_ARCHIVE_VOLUME=$(readlink -f "$DIR/../../volume/video/archive")
export VIDEO_DASH_VOLUME=$(readlink -f "$DIR/../../volume/video/dash")
export VIDEO_HLS_VOLUME=$(readlink -f "$DIR/../../volume/video/hls")
export HTML_VOLUME=$(readlink -f "$DIR/../../volume/html")
export GALLERY_VOLUME=$(readlink -f "$DIR/../../ad-insertion/video-analytics-service/gallery")

sudo docker container prune -f
sudo docker volume prune -f
sudo docker network prune -f
rm -rf "${AD_DASH_VOLUME}" "${AD_HLS_VOLUME}"
mkdir -p "${AD_DASH_VOLUME}" "${AD_HLS_VOLUME}"

PLATFORM=$2
SWARM_NAME="adinsert"
if test -n $PLATFORM; then
    SWARM_NAME="adinsert_${PLATFORM}"
else
    PLATFORM="Xeon"
fi

yml="$DIR/docker-compose.$(hostname).yml.${PLATFORM}"
test -f "$yml" || yml="$DIR/docker-compose.yml.${PLATFORM}"

echo "Platform $PLATFORM with name $SWARM_NAME $yml."

case "$1" in
docker_compose)
    dcv="$(docker-compose --version | cut -f3 -d' ' | cut -f1 -d',')"
    mdcv="$(printf '%s\n' $dcv 1.20 | sort -r -V | head -n 1)"
    if test "$mdcv" = "1.20"; then
        echo ""
        echo "docker-compose >=1.20 is required."
        echo "Please upgrade docker-compose at https://docs.docker.com/compose/install."
        echo ""
        exit 0
    fi

#    . "$DIR/self-sign.sh"
    export USER_ID=$(id -u)
    export GROUP_ID=$(id -g)
    sudo -E docker-compose -f "$yml" -p "$SWARM_NAME" --compatibility up
    ;;
*)
#    . "$DIR/self-sign.sh"
    export USER_ID=$(id -u)
    export GROUP_ID=$(id -g)
    sudo -E docker stack deploy -c "$yml" "$SWARM_NAME"
    ;;
esac
