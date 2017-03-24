#!/bin/bash

if [ "$1" = "--screen" -a -z "$STY" ]; then
  shift
  SCREEN_SESSION=$1; shift
  $ROSWSS_PREFIX screen start $SCREEN_SESSION "roslaunch $ONBOARD_LAUNCH_PKG $@"
else
  roslaunch $ONBOARD_LAUNCH_PKG "$@"
fi
