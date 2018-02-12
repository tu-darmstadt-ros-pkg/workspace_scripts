#!/bin/bash

rosinstall()
{
    local LAST_PWD
    LAST_PWD=$PWD
    cd $ROSWSS_ROOT/src

    local rosinstall

    while [[ ! -z "$1" ]]; do
        rosinstall=$1 # relative path to $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional expected
        echo "> optional/${rosinstall}"
        wstool merge -y $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}
        shift
    done

    cd $LAST_PWD
}
