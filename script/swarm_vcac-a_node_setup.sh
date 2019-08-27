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
puts "\n		 LOGIN ${NODE_IP} SUCCESS  START TO EXCE COMMAND(setup NFS)         "
puts "\n************************************************************************************"
 
expect "${username}@*"  {send "apt install -y nfs-common\r"}
expect "${username}@*"  {send "mkdir -p ${LOCAL_NFS}\r"}
expect "${username}@*"  {send "mount -t nfs ${SERVER_IP}:${SERVER_NFS} ${LOCAL_NFS}\r"}
expect "${username}@*"  {send "systemctl disable firewalld\r"}
expect "${username}@*"  {send "systemctl stop  firewalld\r"}
expect "${username}@*"  {send "\r"}
expect "${username}@*"  {send "\r"}

puts "\n************************************************************************************"
puts "\n                 Add this card in the swarm mode node                               "
puts "\n************************************************************************************"

expect "${username}@*"  {send "docker swarm join --token ${token} ${SERVER_IP}:${port}\r"}

puts "\n************************************************************************************"
puts "\n                 Return to master to setup the node label                           "
puts "\n************************************************************************************"

interact
#expect "${username}@*"  {send "exit\r"}
