#!/bin/bash
if [ "$#" -eq 0 ]; then
    echo "Usage: ssh <HOST> <Command (optional)>"
    exit 1
fi

host=$1; shift
user=$ROBOT_USER

echo "Connecting to $host as $user"
if [ "$#" -eq 0 ]; then
   ssh $user@$host
else
   ssh $user@$host -t 'bash -l -c -i "'$@'"'
fi
