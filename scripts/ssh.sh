#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: ssh <HOST> <Command (optional)>"
    exit 1
fi

host=$1; shift

# Convert to arrays
hosts=($ROBOT_HOSTNAMES)
users=($ROBOT_USERS)

# Check if multiple users are defined
if [ -z "$ROBOT_USERS" ]; then
    # if not, look for single user definition (backwards compatibility)
    if [ -z "$ROBOT_USER" ]; then
        echo_error "ERROR: In order to use the ssh command, please set ROBOT_USER or ROBOT_USERS." 
        exit 1
    else
        user=$ROBOT_USER
    fi
else
    # Else look for the array index of the host name
    for idx in "${!hosts[@]}"; do 
        if [ "${hosts[$idx]}" = "$host" ]; then
            # Take corresponding user
            user="${users[$idx]}"
            break
        fi
    done
fi

# Check if we found a valid user
if [ -z "$user" ]; then
    echo_error "Unknown host '$host'"
    exit
fi

echo_info "Connecting to \"$host\" as \"$user\""
if [ "$#" -eq 0 ]; then
    ssh $user@$host -A
else
    ssh $user@$host -A -t 'bash -l -c -i "'$@'"'
fi
