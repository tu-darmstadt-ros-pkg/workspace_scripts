#!/bin/bash

# DO NOT REMOVE THIS BLOCK UNLESS YOU DON'T WANT TO USE CUSTOM SCRIPTS
@[if DEVELSPACE]@
export ROSWSS_SCRIPTS="@(PROJECT_SOURCE_DIR)/scripts:$ROSWSS_SCRIPTS"
@[else]@
export ROSWSS_SCRIPTS="@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts:$ROSWSS_SCRIPTS"
@[end if]@

# SET HERE YOUR WORKSPACE PREFIX
export ROSWSS_PREFIX="roswss"
export ROSWSS_ROOT_RELATIVE_PATH="../.."    # Relative path to workspace root from package location

# SETUP YOUR ENVIRONMENT HERE
export ONBOARD_LAUNCH_PKG=""                # Name of your main onboard launch package
export ONBOARD_LAUNCH_FILE=""               # Name of your main onboard launch file
export UI_LAUNCH_PKG=""                     # Name of your main ui launch package
export GAZEBO_LAUNCH_PKG=""                 # Gazebo launch package
export GAZEBO_DEFAULT_LAUNCH_FILE=""        # Gazebo default launch file
export GAZEBO_WORLDS_PKG=""                 # Package name where your Gazebo worlds are stored
export AUTOSTART_LAUNCH_PKG=""              # Package containing autostart setup
export ROBOT_MASTER_HOSTNANE=""             # Hostname running ros master
export ROBOT_HOSTNAMES=""                   # Hostnames of all available robot computers
export ROBOT_USER=""                        # Main login user name for robot computers

# SETUP YOUR REMOTE PCs HERE
# Use add_remote_pc to register different remote pcs
# Example:
#   add_remote_pc "motion" "thor-motion" "motion" "roslaunch thor_mang_onboard_launch motion.launch"

# REGISTER CUSTOM COMPLETION SCRIPTS HERE
# Use add_completion to register additional auto completion scripts
# Example:
#   add_completion "my_command" "completion_function"
