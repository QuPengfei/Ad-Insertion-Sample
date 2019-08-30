#!/bin/bash -e

DIR=$(dirname $(readlink -f "$0"))

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
    mdcv="$(printf '%s\n' $dcv 1.10 | sort -r -V | head -n 1)"
    if test "$mdcv" = "1.10"; then
        echo ""
        echo "docker-compose >=1.10 is required."
        echo "Please upgrade docker-compose at https://docs.docker.com/compose/install."
        echo ""
        exit 0
    fi
    sudo docker-compose -f "$yml" -p "$SWARM_NAME" --compatibility down
    ;;
*)
    sudo docker stack rm "$SWARM_NAME"
    ;;
esac

sudo docker container prune -f
sudo docker volume prune -f
sudo docker network prune -f
