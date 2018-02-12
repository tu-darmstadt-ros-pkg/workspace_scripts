#!/bin/bash

rosinstall()
{
    local rosinstall
    rosinstall=$1 # relative path to $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional expected
    shift

    local LAST_PWD
    LAST_PWD=$PWD
    cd $ROSWSS_ROOT/src

    while [[ ! -z "$rosinstall" ]]; do
      echo "> optional/${rosinstall}"
      wstool merge -y $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}
      rosinstall=$1
      shift
    done

    cd $LAST_PWD
}
