#!/bin/bash
export ROBOT_PC_SCRIPTS=()

# Use this method to register different robot pcs
# Example:
#   add_robot_pc "motion" "thor-motion" "motion" "roslaunch thor_mang_onboard_launch motion.launch"
function add_robot_pc() {
    script_name="$1"
    export ${script_name}_script_name="$1"
    export ${script_name}_hostname="$2"
    export ${script_name}_screen_name="$3"
    export ${script_name}_launch_command="$4"
    ROBOT_PC_SCRIPTS+=($script_name)
}

# SET HERE YOUR WORKSPACE PREFIX
export ROSWSS_PREFIX="roswss"
export ROSWSS_ROOT_RELATIVE_PATH="../.."    # Relative path to workspace root from package location

# SETUP YOUR ENVIRONMENT HERE
export ONBOARD_LAUNCH_PKG=""                # Name of your main onboard launch package
export GAZEBO_LAUNCH_PKG=""                 # Package name where your Gazebo worlds are stored
export GAZEBO_WORLDS_PKG=""                 # Package name where your Gazebo worlds are stored
export ROBOT_MASTER_HOSTNANE=""             # Hostname running ros master
export ROBOT_HOSTNAMES=""                   # Hostnames of all available robot computers
export ROBOT_USER=""                        # Main login user name for robot computers
