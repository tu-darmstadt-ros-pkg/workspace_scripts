#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: broadcast <Command>"
    exit 1
fi
echo "1"
shift
command=$@;

hosts=($ROBOT_HOSTNAMES)
users=($ROBOT_USERS)

for idx in "${!hosts[@]}"; do 
    host="${hosts[$idx]}"
    user="${users[$idx]}"
    echo "Executing $command on $host"
    $dir/ssh.sh $host $command
done

