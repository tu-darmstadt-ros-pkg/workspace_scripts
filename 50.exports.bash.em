#!/bin/bash

# export important variables (do not change!)
export HOSTNAME=$(hostname)
export ROSWSS_ROOT=$(cd "@(CMAKE_SOURCE_DIR)"/$ROSWSS_ROOT_RELATIVE_PATH; pwd)
export ROS_WORKSPACE=$ROSWSS_ROOT/src

# source completion files
for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -d "$dir/completion" ]; then
        for file in `find -L $dir/completion/ -maxdepth 1 -type f -name "*.sh"`; do
            source $file
        done
    fi
done

# default auto completion
add_completion "install" "_roswss_install_complete"
add_completion "make" "_catkin_pkgs_complete"
add_completion "rosdoc" "_roswss_rosdoc_complete"
add_completion "test" "_roswss_test_complete"
add_completion "ui" "_roswss_ui_complete"
add_completion "uninstall" "_roswss_uninstall_complete"
add_completion "update" "_catkin_pkgs_complete"
