#!/usr/bin/env bash

logfile=node.txt

#node_list=$(`sudo -E docker node ls|awk '{print $1}' `)
sudo -E docker node ls -q > $logfile 

idx=1
#cat ${logfile} | while read line
for line in $(cat $logfile)
do 
    #echo ${line}
    node=$(awk 'NR=='$idx' {print $1}' ${logfile})
    flag=$(awk 'NR=='$idx' {print $2}' ${logfile})
    if [[ $idx == 1 ]]; then
        echo "master"
        #sudo docker node update $node --label-add ad-insert-manager=true
    else
        echo "worker"
        #sudo docker node update $node --label-add ad-insert-worker=true
    fi
    echo $idx $node $flag
    : $(( idx++ ))
done
