#!/usr/bin/expect
set timeout 600 
set RUN_PATH "/mnt/nfs"
set username root 
set password vista1
set hostname 172.32.1.1
set token [lindex $argv 0]
set port 2377

spawn ssh $username@$hostname
expect {
"yes/no"
{send "yes\r"; exp_continue;}  
"password:"
{send "$password\r";}
"Password:"
{send "$password\r";}
}

puts "\n************************************************************************************"
puts "\n		 LOGIN ${hostname} SUCCESS  START TO EXCE COMMAND	"
puts "\n************************************************************************************"
 
expect "${username}@*"  {send "cd ${RUN_PATH}\r"}
expect "${username}@*"  {send "bash Swarm_vcac-a_node_run.sh\r"}

puts "\n************************************************************************************"
puts "\n                 Add this card in the swarm mode node                               "
puts "\n************************************************************************************"

expect "${username}@*"  {send "docker swarm join --token ${token} ${hostname}:${port}\r"}

puts "\n************************************************************************************"
puts "\n                 Start the HDDL Damen                                               "
puts "\n************************************************************************************"

expect "${username}@*"  {send "source /opt/intel/openvino/bin/setupvars.sh\r"}
expect "${username}@*"  {send "/opt/intel/openvino/deployment_tools/inference_engine/external/hddl/bin/hddldaemon\r"}

interact
