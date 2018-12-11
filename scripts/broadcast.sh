#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: broadcast <Command>"
    exit 1
fi
command=$@;

hosts=($ROBOT_HOSTNAMES)
users=($ROBOT_USERS)
counter=0;

for idx in "${!hosts[@]}"; do 
    host="${hosts[$idx]}"
    user="${users[$idx]}"
    echo "Executing $command on $host"
    xterm -T "$host" -geometry 80x25+$counter+0 -e ssh $user@$host -A -t 'bash -l -c -i "'$@'" ; sleep 7' &
    counter=$(( $counter + 500 ))
done

