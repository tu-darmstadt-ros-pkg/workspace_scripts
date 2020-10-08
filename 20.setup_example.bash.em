#!/bin/bash

# DO NOT REMOVE THIS LINE UNLESS YOU DON'T WANT TO USE CUSTOM SCRIPTS
@[if DEVELSPACE]@
export ROSWSS_SCRIPTS="@(PROJECT_SOURCE_DIR)/scripts:$ROSWSS_SCRIPTS"
@[else]@
export ROSWSS_SCRIPTS="@(CMAKE_INSTALL_PREFIX)/@(CATKIN_PACKAGE_SHARE_DESTINATION)/scripts:$ROSWSS_SCRIPTS"
@[end if]@

# SET HERE YOUR WORKSPACE PREFIX
export ROSWSS_PREFIX="roswss"               # Replace with your preferred command name
export ROSWSS_ROOT_RELATIVE_PATH="../.."    # Relative path to workspace root from package location
export ROSWSS_INSTALL_DIR="rosinstall"      # Path/Directory to install files (relative to workspace root dir)

# SETUP YOUR ENVIRONMENT HERE (all fields are optional)
export ONBOARD_LAUNCH_PKG=""                # Name of your main onboard launch package; Required for "launch" command.
export UI_LAUNCH_PKG=""                     # Name of your main ui launch package; Required for "ui" command.
export UI_DEFAULT_LAUNCH_FILE=""            # Name of your default ui launch file
export GAZEBO_LAUNCH_PKG=""                 # Gazebo launch package; Required for "sim" command.
export GAZEBO_DEFAULT_LAUNCH_FILE=""        # Gazebo default launch file; Required for "sim" command.
export AUTOSTART_LAUNCH_PKG=""              # Package containing autostart setup
export ROBOT_MASTER_HOSTNAME=""             # Hostname running ros master; Required for "sync" (clock synchronization) command.
export ROBOT_HOSTNAMES=""                   # Hostnames of all available robot computers; Required for "master" command. Hostnames are space seperated, i.e. "host1 host2".
export ROBOT_USER=""                        # Main login user name for robot computers; Required for starting ssh sessions.
export ROBOT_USERS=""                       # Different login user name for robot computers; Required for starting ssh sessions on multiple computers using different user names for each.

# additional build flags given to catkin build by default (see: https://catkin-tools.readthedocs.io/en/latest/verbs/catkin_build.html#full-command-line-interface)
export CATKIN_BUILD_FLAGS="--continue-on-failure"

# SETUP YOUR REMOTE PCs HERE
# Use add_remote_pc to register different remote pcs
# Syntax:
#   add_remote_pc "<script_name>" "<host_name>" "<screen_name>" "<command>"
# Example:
#   add_remote_pc "motion" "thor-motion" "motion" "roslaunch thor_mang_onboard_launch motion.launch"

# REGISTER CUSTOM COMPLETION SCRIPTS HERE
# NOTE: These may be overritten by default completion functions. In order to avoid this behavior, please define a 51.exports.bash.em (51 or greater) and call add_completion from this file.
# Use add_completion to register additional auto completion scripts
# Example:
#   add_completion "my_command" "completion_function"
