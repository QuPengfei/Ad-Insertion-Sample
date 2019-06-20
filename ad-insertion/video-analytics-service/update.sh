#!/bin/bash -e

DIR=$(dirname $(readlink -f "$0"))

# ffmpeg base dockerfile
DOCKER_REPO="https://raw.githubusercontent.com/OpenVisualCloud/Dockerfiles/master/Xeon/ubuntu-18.04/analytics/ffmpeg"

base_name=xeon-ubuntu1804-dldt-ffmpeg-va
docker_file="$DIR/Dockerfile.4.ffmpeg"

echo "# "${base_name} > ${docker_file}
curl ${DOCKER_REPO}/Dockerfile >> ${docker_file}

# gst base dockerfile
DOCKER_REPO="https://raw.githubusercontent.com/OpenVisualCloud/Dockerfiles/master/Xeon/ubuntu-18.04/analytics/gst"

base_name=xeon-ubuntu1804-dldt-gst-va
docker_file="$DIR/Dockerfile.2.gst"

echo "# "${base_name} > ${docker_file}
curl ${DOCKER_REPO}/Dockerfile>> ${docker_file}
