#!/bin/bash

rosinstall()
{
    local rosinstall
    rosinstall=$1 # relative path to $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional expected
    local LAST_PWD
    LAST_PWD=$PWD

    cd $ROSWSS_ROOT/src
    wstool merge -y $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}
    cd $LAST_PWD
}
