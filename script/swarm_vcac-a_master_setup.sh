#!/usr/bin/env bash

if [[ -f /etc/centos-release ]]; then
    DISTRO="centos"
elif [[ -f /etc/lsb-release ]]; then
    DISTRO="ubuntu"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    DISTRO="macos"
fi


SERVER_IP=172.32.1.254
NODE_IP=172.32.1.1
SERVER_NFS=/mnt/nfs
LOCAL_NFS=/mnt/nfs
SEVER_LABEL=ad-insert-manager
NODE_LABEL=ad-insert-worker-hkh

printf "##########################################################\n"
printf "############ Setup NFS on the Server Side ################\n"
printf "##########################################################\n"
if [[ $DISTRO == "centos" ]]; then
    # setup the NFS on the E5 server
    sudo -E yum install -y expect.x86_64
    sudo -E yum install -y rpcbind nfs-utils

    sudo -E mkdir -p ${SERVER_NFS} 
    echo "${SERVER_NFS} *(rw,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)" | sudo tee -a /etc/exports

    sudo -E systemctl enable rpcbind.service
    sudo -E systemctl enable nfs-server.service

    sudo -E systemctl start rpcbind.service
    sudo -E systemctl start nfs-server.service

    # stop the firewall
    sudo -E systemctl disable firewalld
    sudo -E systemctl stop  firewalld

    sudo -E exportfs -r
    sudo -E exportfs
elif [[ $DISTRO == "ubuntu" ]]; then
    sudo -E apt install -y nfs-kernel-server
    sudo -E apt install -y nfs-common
    sudo -E /etc/init.d/nfs-kernel-server restart

    # stop the firewall
    sudo -E systemctl disable firewalld
    sudo -E systemctl stop  firewalld

    sudo -E mkdir -p ${SERVER_NFS}
    #sudo -E echo "${SERVER_NFS} *(rw,no_root_squash,no_all_squash,sync,anonuid=501,anongid=501)" >> /etc/exports
    echo "${SERVER_NFS} *(rw,sync,no_root_squash,no_subtree_check)" | sudo tee -a /etc/exports
    showmount -e ${SERVER_IP}
else 
    printf "VCAC-A does Not support on ${DISTRO}\n"
fi

printf "##########################################################\n"
printf "############ Setup Swarm on the manager and node   #######\n"
printf "##########################################################\n"
Token=`sudo -E docker swarm join-token -q worker`

if [[ "$Token" == "" ]]; then
    T1=`sudo -E docker swarm init --advertise-addr 172.32.1.254 |grep token`
    echo $T1
    T2="To"
    #echo $(expr index "$T1" "$T2")
    Token_END=$(expr index "$T1" "$T2")
    echo $Token_END
    Token=`sudo docker swarm join-token -q worker`
fi

echo $Token | sudo tee "${SERVER_NFS}/token.txt"


printf "##########################################################\n"
printf "############ login to the Node and setup the env   #######\n"
printf "##########################################################\n"
exec ./swarm_vcac-a_node_setup.sh $Token 

printf "##########################################################\n"
printf "############ update the node label                 #######\n"
printf "##########################################################\n"
logfile=node.txt

sudo -E docker node ls  -f "role=manager" -q > $logfile
echo "label manager"
sudo docker node update $node --label-add ${SEVER_LABEL}=true
        
sudo -E docker node ls  -f "role=worker" -q > $logfile
echo "worker"
sudo docker node update $node --label-add ${NODE_LAEL}=true

rm -f $logfile
