#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: broadcast <Command>"
    exit 1
fi
command=$@;

if [ -z "$command" ]; then
  echo_error "No command specified"
  exit
fi

hosts=($ROBOT_HOSTNAMES)
users=($ROBOT_USERS)
screen_session=$command


for idx in "${!hosts[@]}"; do 
    host="${hosts[$idx]}"
    user="${users[$idx]}"
    echo "Executing $command on $host"
    ssh $user@$host "screen -dmLS $screen_session bash -c $command"
    
done

