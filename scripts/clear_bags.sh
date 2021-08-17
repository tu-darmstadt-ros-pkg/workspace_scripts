#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -eq 0 ]; then
    if [ -z "$LOGGING_PKG" ]; then
        echo "WARNING: LOGGING_PKG was not set, assume default robot_onboard_logging"
        logging_dir=$(rospack find 'robot_onboard_logging')
    else
        logging_dir=$(rospack find $LOGGING_PGK)
    fi


    echo -ne "${YELLOW}Are you sure to delete bags, 2d and 3d maps? [y/N] ${NOCOLOR}"
    read -N 1 REPLY
    echo

    if [[ "$REPLY" = "y" || "$REPLY" = "Y" ]]; then

        rm -f "$logging_dir/bags/"*.bag
        rm -f "$logging_dir/bags/"*.bag.active
        rm -f "$logging_dir/bags/"*.urdf
        rm -f "$logging_dir/maps/"*
        rm -f "$logging_dir/octomaps/"*.bt

    else
        echo_info "Delete cancelled"
    fi
else

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
    ssh $user@$host -A -t 'bash -l -c -i "hector clear_bags"'
fi
