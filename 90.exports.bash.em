#!/bin/bash

# export important variables (do not change!)
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
