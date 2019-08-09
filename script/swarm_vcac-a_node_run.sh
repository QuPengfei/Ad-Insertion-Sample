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

if [[ $DISTRO == "centos" ]]; then
    # setup the NFS on the E5 server
    sudo -E yum install -y nfs-utils

    mkdir -p ${SERVER_NFS}

    sudo -E systemctl enable rpcbind.service
    sudo -E systemctl start rpcbind.service
    # stop the firewall
    sudo -E systemctl disable firewalld
    sudo -E systemctl stop  firewalld

    showmount -e ${SERVER_IP}
    mkdir -p ${LOCAL_NFS}
    sudo mount -t nfs ${SERVER_IP}:${SERVER_NFS} ${LOCAL_NFS}
elif [[ $DISTRO == "ubuntu" ]]; then
    sudo -E apt install -y nfs-kernel-server
    sudo -E /etc/init.d/nfs-kernel-server restart
    sudo -E apt install -y nfs-common
    # stop the firewall
    sudo -E systemctl disable firewalld
    sudo -E systemctl stop  firewalld

    showmount -e ${SERVER_IP}
    mkdir -p ${LOCAL_NFS}
    sudo mount -t nfs ${SERVER_IP}:${SERVER_NFS} ${LOCAL_NFS}
else
    printf "VCAC-A does Not support on ${DISTRO}\n"
fi
