#!/bin/bash

# only execute autostart if specified
if [ -z "$AUTOSTART_LAUNCH_PKG" ]; then
    echo "WARNING: autostart.sh has been triggered but AUTOSTART_LAUNCH_PKG was not set!" 
    return
fi

# include helper functions
for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -f $dir/helper/robot_bringup.sh ]; then
        source $dir/helper/robot_bringup.sh
    fi

    if [ -f $dir/helper/robot_bringup.sh ]; then
        source $dir/helper/robot_bringup.sh ""
    fi
done

autostart_dir=$(rospack find $AUTOSTART_LAUNCH_PKG)

# include setup hooks
_robot_bringup_include "$autostart_dir/setup.d/*.sh"
_robot_bringup_include "$autostart_dir/setup.d/$HOSTNAME/*.sh"

# auto startup
_robot_bringup_run "$autostart_dir/autostart.d/*.sh"
_robot_bringup_run "$autostart_dir/autostart.d/$HOSTNAME/*.sh"
