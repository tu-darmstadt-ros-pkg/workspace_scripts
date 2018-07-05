#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# only execute if ONBOARD_LAUNCH_PKG is set
if [ -z "$ONBOARD_LAUNCH_PKG" ]; then
    echo_error "ERROR: In order to use the launch command, please set ONBOARD_LAUNCH_PKG." 
    exit 1
fi

if [ "$1" = "--screen" -a -z "$STY" ]; then
  shift
  SCREEN_SESSION=$1; shift
  roswss screen start $SCREEN_SESSION "roslaunch $ONBOARD_LAUNCH_PKG $@"
else
  roslaunch $ONBOARD_LAUNCH_PKG "$@"
fi
