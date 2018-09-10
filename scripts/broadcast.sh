#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: broadcast <Command>"
    exit 1
fi
echo "1"
command=$1; shift

hosts=($ROBOT_HOSTNAMES)
users=($ROBOT_USERS)

for idx in "${!hosts[@]}"; do 
    host="${hosts[$idx]}"
    user="${users[$idx]}"
    $dir/ssh.sh $host $command
    echo "Executing $command on $host"
done

