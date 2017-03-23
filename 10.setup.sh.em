#!/bin/sh

# SET HERE YOUR WORKSPACE PREFIX
export ROSWS_PREFIX="rosws"

# SETUP YOUR ENVIRONMENT HERE
export ONBOARD_LAUNCH_PKG=""            # Name of your main onboard launch package
export GAZEBO_LAUNCH_PKG=""             # Package name where your Gazebo worlds are stored
export GAZEBO_WORLDS_PKG=""             # Package name where your Gazebo worlds are stored
export ROBOT_MASTER_HOSTNANE=""         # Hostname running ros master
export ROBOT_HOSTNAMES=""               # Hostnames of all available robot computers
export ROBOT_USER=""                    # Main login user name for robot computers
