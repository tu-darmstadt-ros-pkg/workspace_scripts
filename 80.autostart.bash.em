#!/bin/bash

# only execute autostart if specified
if [ -z "$AUTOSTART_LAUNCH_PKG" ]; then
    return
fi  

# include helper functions
for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -f $dir/helper/functions.sh ]; then
        source $dir/helper/functions.sh
    fi

    if [ -f $dir/helper/robot.sh ]; then
        source $dir/helper/robot.sh ""
    fi
done

autostart_dir=$(rospack find $AUTOSTART_LAUNCH_PKG)

# include setup hooks
_robot_include "$autostart_dir/setup.d/*.sh"
_robot_include "$autostart_dir/$HOSTNAME/setup.d/*.sh"

if [ -r "$autostart_dir/$HOSTNAME/setup.sh" ]; then
  echo "Including $autostart_dir/$HOSTNAME/setup.sh..." >&2
  source "$autostart_dir/$HOSTNAME/setup.sh"
fi

# auto startup
_robot_run "$autostart_dir/autostart.d/*.sh"
_robot_run "$autostart_dir/$HOSTNAME/autostart.d/*.sh"
