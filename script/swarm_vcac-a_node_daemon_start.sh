#!/usr/bin/expect
set timeout 600 
set username root 
set password vista1
set NODE_IP 172.32.1.1

spawn ssh $username@$NODE_IP
expect {
"yes/no"
{send "yes\r"; exp_continue;}  
"password:"
{send "$password\r";}
"Password:"
{send "$password\r";}
}

expect "${username}@*"  {send "source /opt/intel/openvino/bin/setupvars.sh\r"}
expect "${username}@*"  {send "/opt/intel/openvino/deployment_tools/inference_engine/external/hddl/bin/hddldaemon\r"}

interact
