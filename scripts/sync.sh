#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# only execute if ROBOT_MASTER_HOSTNAME is set
if [[ -z "$1" && -z "$ROBOT_MASTER_HOSTNAME" ]]; then
    echo_error "ERROR: In order to use the sync command, please set ROBOT_MASTER_HOSTNAME" 
    exit 1
fi

return

sudo /etc/init.d/chrony stop

if [ "$#" -lt 1 ]; then
  sudo ntpdate $ROBOT_MASTER_HOSTNAME
else
  sudo ntpdate $1
fi

sudo /etc/init.d/chrony start
