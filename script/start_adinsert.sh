#!/bin/bash -e

PLATFORM=$1
if test -z $PLATFORM; then
    echo "Platform must be Xeon or VCAC-A."
    exit
fi

echo "Start the AD insertion Sample on ${PLATFORM}."
cd ../deployment/docker-swarm/

if test $PLATFORM = "VCAC-A"; then 
    sh start.sh docker_swarm $PLATFORM
elif test $PLATFORM = "Xeon"; then
    sh start.sh docker_swarm $PLATFORM
fi
