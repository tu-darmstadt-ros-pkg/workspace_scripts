#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# only execute if ROBOT_USER is set
if [ -z "$ROBOT_USER" ]; then
    echo_error "ERROR: In order to use the ssh command, please set ROBOT_USER." 
    exit 1
fi

if [ "$#" -eq 0 ]; then
    echo "Usage: ssh <HOST> <Command (optional)>"
    exit 1
fi

host=$1; shift
user=$ROBOT_USER

echo_info "Connecting to $host as $user"
if [ "$#" -eq 0 ]; then
   ssh $user@$host -A
else
   ssh $user@$host -A -t 'bash -l -c -i "'$@'"'
fi
