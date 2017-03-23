#!/bin/sh

@[if DEVELSPACE]@
export ROSWS_SCRIPTS=@(PROJECT_SOURCE_DIR)/scripts
@[else]@
export ROSWS_SCRIPTS=@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts
@[end if]@
export ROSWS_ROOT=$(cd "@(CMAKE_SOURCE_DIR)/../../.."; pwd)

# include ROSWS_scripts hooks
#if [ -d $ROSWS_SCRIPTS ]; then
#  . $ROSWS_SCRIPTS/functions.sh
#  . $ROSWS_SCRIPTS/robot.sh ""

#  _ROSWS_include "$ROSWS_SCRIPTS/setup.d/*.sh"
#  _ROSWS_include "$ROSWS_SCRIPTS/$HOSTNAME/setup.d/*.sh"

#  if [ -r "$ROSWS_SCRIPTS/$HOSTNAME/setup.sh" ]; then
#      echo "Including $ROSWS_SCRIPTS/$HOSTNAME/setup.sh..." >&2
#      . "$ROSWS_SCRIPTS/$HOSTNAME/setup.sh"
#  fi
#fi

# export additional ROS_PACKAGE_PATH for indigo
if [ "$ROS_DISTRO" = "indigo" ]; then
    export ROS_BOOST_LIB_DIR_NAME=/usr/lib/x86_64-linux-gnu
    export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$ROS_WORKSPACE/../external
fi

# export some variables
export PATH=$ROSWS_SCRIPTS/helper:$PATH
export ROS_WORKSPACE=$ROSWS_ROOT/src
