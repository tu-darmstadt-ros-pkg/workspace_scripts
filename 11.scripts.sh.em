#!/bin/sh

@[if DEVELSPACE]@
export ROSWSS_SCRIPTS=@(PROJECT_SOURCE_DIR)/scripts
@[else]@
export ROSWSS_SCRIPTS=@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts
@[end if]@
export ROSWSS_ROOT=$(cd "@(CMAKE_SOURCE_DIR)/$ROSWSS_ROOT_RELATIVE_PATH"; pwd)

# include ROSWSS_scripts hooks
#if [ -d $ROSWSS_SCRIPTS ]; then
#  . $ROSWSS_SCRIPTS/functions.sh
#  . $ROSWSS_SCRIPTS/robot.sh ""

#  _ROSWSS_include "$ROSWSS_SCRIPTS/setup.d/*.sh"
#  _ROSWSS_include "$ROSWSS_SCRIPTS/$HOSTNAME/setup.d/*.sh"

#  if [ -r "$ROSWSS_SCRIPTS/$HOSTNAME/setup.sh" ]; then
#      echo "Including $ROSWSS_SCRIPTS/$HOSTNAME/setup.sh..." >&2
#      . "$ROSWSS_SCRIPTS/$HOSTNAME/setup.sh"
#  fi
#fi

# export additional ROS_PACKAGE_PATH for indigo
if [ "$ROS_DISTRO" = "indigo" ]; then
    export ROS_BOOST_LIB_DIR_NAME=/usr/lib/x86_64-linux-gnu
    export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$ROS_WORKSPACE/../external
fi

# export some variables
export PATH=$ROSWSS_SCRIPTS/helper:$PATH
export ROS_WORKSPACE=$ROSWSS_ROOT/src
