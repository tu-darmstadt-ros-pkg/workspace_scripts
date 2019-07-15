#!/bin/bash

# export important variables (do not change!)
export HOSTNAME=$(hostname)
@[if DEVELSPACE]@
export ROSWSS_ROOT=$(cd "@(CMAKE_SOURCE_DIR)"/$ROSWSS_ROOT_RELATIVE_PATH; pwd)
export ROSWSS_LOG_DIR="${ROSWSS_ROOT}/logs"
@[else]@
export ROSWSS_ROOT="@(CMAKE_INSTALL_PREFIX)"
export ROSWSS_LOG_DIR="${HOME}/logs"
@[end if]@
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
add_completion "clean" "_roswss_clean_complete"
add_completion "install" "_roswss_install_complete"
add_completion "make" "_catkin_pkgs_complete"
add_completion "rosdoc" "_roswss_rosdoc_complete"
add_completion "test" "_roswss_test_complete"
add_completion "ui" "_roswss_ui_complete"
add_completion "uninstall" "_roswss_uninstall_complete"
add_completion "update" "_catkin_pkgs_complete"
