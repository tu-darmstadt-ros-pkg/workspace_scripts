#!/bin/bash

source ${ROSWSS_BASE_SCRIPTS}/helper/helper.sh

apt_install sshfs

if [ "$#" -lt 3 ]; then
    echo "Usage: sshfs host remote_dir local_dir"
    exit 1
fi

# extract arguments
host=$1; shift
remote_dir="$1"; shift
local_dir="$1"; shift

# convert to arrays
hosts=(${ROBOT_HOSTNAMES})
users=(${ROBOT_USERS})

# check if multiple users are defined
if [ -z "${ROBOT_USERS}" ]; then
    # if not, look for single user definition (backwards compatibility)
    if [ -z "${ROBOT_USER}" ]; then
        echo_error "ERROR: In order to use the sshfs command, please set ROBOT_USER or ROBOT_USERS." 
        exit 1
    else
        user=${ROBOT_USER}
    fi
else
    # else look for the array index of the host name
    for idx in "${!hosts[@]}"; do 
        if [ "${hosts[$idx]}" = "${host}" ]; then
            # take corresponding user
            user="${users[$idx]}"
            break
        fi
    done
fi

# check if we found a valid user
if [ -z "${user}" ]; then
    echo_error "Unknown host '${host}'"
    exit
fi

# check if mounting dir is available at the local system
mkdir -p ${local_dir}
if [ ! -z "$(ls -A ${local_dir})" ]; then
    echo_error "Mount directory \"${local_dir}\" is not empty!"
    exit 1
fi

# connect via SSHFS
echo_info "Connecting to machine \"${host}\" as user \"${user}\"..."
echo_info "Mounting remote path \"${remote_dir}\" to \"${local_dir}\"..."
sshfs ${user}@${host}:${remote_dir} ${local_dir} -o ServerAliveInterval=15 -o idmap=user -o uid=$(id -u) -o gid=$(id -g) "$@"
