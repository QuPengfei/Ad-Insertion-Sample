#!/usr/bin/expect
set timeout 600
set username root
set password vista1
set token [lindex $argv 0]
set port 2377

set SERVER_IP 172.32.1.254
set NODE_IP 172.32.1.1
set SERVER_NFS "/mnt/nfs"
set LOCAL_NFS "/mnt/nfs"

spawn ssh $username@$NODE_IP
expect {
"yes/no"
{send "yes\r"; exp_continue;}
"password:"
{send "$password\r";}
"Password:"
{send "$password\r";}
}

puts "\n************************************************************************************"
puts "\n                 LOGIN ${NODE_IP} SUCCESS  START TO load the images from NFS        "
puts "\n************************************************************************************"

expect "${username}@*"  {send "cd ${LOCAL_NFS}\r"}
expect "${username}@*"  {send "docker rmi video_analytics_service_gstreamer_vcac_a -f\r"}
expect "${username}@*"  {send "docker rmi video_analytics_service_ffmpeg_vcac_a -f\r"}
expect "${username}@*"  {send "docker load -i video_analytics_service_gstreamer_vcac_a-latest.tar\r"}
expect "${username}@*"  {send "docker load -i video_analytics_service_ffmpeg_vcac_a-latest.tar\r"}
expect "${username}@*"  {send "docker load -i docker-latest.tar\r"}
expect "${username}@*"  {send "\r"}
expect "${username}@*"  {send "\r"}

interact

