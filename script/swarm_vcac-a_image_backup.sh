#!/usr/bin/env bash

SERVER_NFS="/mnt/nfs"

echo "\n************************************************************************************"
echo "\n                 Save the VA service image for VCAC-A platform on NFS               "
echo "\n************************************************************************************"
cd $SERVER_NFS
pwd

echo "sudo docker image save video_analytics_service_gstreamer_vcac_a:latest -o video_analytics_service_gstreamer_vcac_a-latest.tar"
sudo docker image save video_analytics_service_gstreamer_vcac_a:latest -o video_analytics_service_gstreamer_vcac_a-latest.tar

echo "sudo docker image save video_analytics_service_ffmpeg_vcac_a:latest -o video_analytics_service_ffmpeg_vcac_a-latest.tar"
sudo docker image save video_analytics_service_ffmpeg_vcac_a:latest -o video_analytics_service_ffmpeg_vcac_a-latest.tar

echo "sudo docekr image save docker:latest -o docker-latest.tar"
sudo docekr image save docker:latest -o docker-latest.tar
