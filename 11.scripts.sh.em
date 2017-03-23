#!/bin/sh

@[if DEVELSPACE]@
export WS_SCRIPTS=@(PROJECT_SOURCE_DIR)/scripts
@[else]@
export WS_SCRIPTS=@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts
@[end if]@
export WS_ROOT=$(cd "@(CMAKE_SOURCE_DIR)/../../.."; pwd)

# include WS_scripts hooks
#if [ -d $WS_SCRIPTS ]; then
#  . $WS_SCRIPTS/functions.sh
#  . $WS_SCRIPTS/robot.sh ""

#  _WS_include "$WS_SCRIPTS/setup.d/*.sh"
#  _WS_include "$WS_SCRIPTS/$HOSTNAME/setup.d/*.sh"

#  if [ -r "$WS_SCRIPTS/$HOSTNAME/setup.sh" ]; then
#      echo "Including $WS_SCRIPTS/$HOSTNAME/setup.sh..." >&2
#      . "$WS_SCRIPTS/$HOSTNAME/setup.sh"
#  fi
#fi

# export additional ROS_PACKAGE_PATH for indigo
if [ "$ROS_DISTRO" = "indigo" ]; then
    export ROS_BOOST_LIB_DIR_NAME=/usr/lib/x86_64-linux-gnu
    export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$ROS_WORKSPACE/../external
fi

# export some variables
export PATH=$WS_SCRIPTS/helper:$PATH
export ROS_WORKSPACE=$WS_ROOT/src
