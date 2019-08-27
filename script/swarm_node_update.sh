#!/usr/bin/env bash

printf "##########################################################\n"
printf "############ update the node label                 #######\n"
printf "##########################################################\n"
SEVER_LABEL=ad-insert-manager
NODE_LABEL=ad-insert-worker-hkh

node=`sudo -E docker node ls  -f "role=manager" -q `
echo "manager" $node $SEVER_LABEL
echo "sudo docker node update $node --label-add ${SEVER_LABEL}=true"
sudo docker node update $node --label-add ${SEVER_LABEL}=true

node=`sudo -E docker node ls  -f "role=worker" -q `
echo "worker" $node $NODE_LABEL
echo "sudo docker node update $node --label-add ${NODE_LABEL}=true"
sudo docker node update $node --label-add ${NODE_LABEL}=true
