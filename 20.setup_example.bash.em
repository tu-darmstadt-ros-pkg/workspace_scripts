#!/bin/bash

# DO NOT REMOVE THIS LINE UNLESS YOU DON'T WANT TO USE CUSTOM SCRIPTS
export ROSWSS_SCRIPTS="@(PROJECT_SOURCE_DIR)/scripts:$ROSWSS_SCRIPTS"

# SET HERE YOUR WORKSPACE PREFIX
export ROSWSS_PREFIX="roswss"               # Replace with your preferred command name
export ROSWSS_ROOT_RELATIVE_PATH="../.."    # Relative path to workspace root from package location
export ROSWSS_INSTALL_DIR="rosinstall"      # Path/Directory to install files (relative to workspace root dir)

# SETUP YOUR ENVIRONMENT HERE (all fields are optional)
export ONBOARD_LAUNCH_PKG=""                # Name of your main onboard launch package; Required for "launch" command.
export UI_LAUNCH_PKG=""                     # Name of your main ui launch package; Required for "ui" command.
export GAZEBO_LAUNCH_PKG=""                 # Gazebo launch package; Required for "sim" command.
export GAZEBO_DEFAULT_LAUNCH_FILE=""        # Gazebo default launch file; Required for "sim" command.
export GAZEBO_WORLDS_PKG=""                 # Package name where your Gazebo worlds are stored; Required for "sim" command.
export AUTOSTART_LAUNCH_PKG=""              # Package containing autostart setup
export ROBOT_MASTER_HOSTNANE=""             # Hostname running ros master; Required for "sync" (clock synchronization) command.
export ROBOT_HOSTNAMES=""                   # Hostnames of all available robot computers; Required for "master" command.
export ROBOT_USER=""                        # Main login user name for robot computers; Required for starting ssh sessions.

# SETUP YOUR REMOTE PCs HERE
# Use add_remote_pc to register different remote pcs
# Syntax:
#   add_remote_pc "<script_name>" "<host_name>" "<screen_name>" "<command>"
# Example:
#   add_remote_pc "motion" "thor-motion" "motion" "roslaunch thor_mang_onboard_launch motion.launch"

# REGISTER CUSTOM COMPLETION SCRIPTS HERE
# Use add_completion to register additional auto completion scripts
# Example:
#   add_completion "my_command" "completion_function"
