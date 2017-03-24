#!/bin/bash

. $ROSWSS_ROOT/setup.bash

versions="2, 4, 5, 6, 7"

valid_version=false

sudo echo

version=$1
if [[ $version ]]; then
    if [[ $versions =~ $version ]]; then
        valid_version=true
    fi
fi

while [ $valid_version = false ]; do
    read -p "Which version of Gazebo do you want to install (2, 4, 5, 6, 7)?" version
    if [[ $versions =~ $version ]]; then
        valid_version=true
    else
        echo "Invalid Gazebo version number. Enter 2, 4, 5, 6 or 7."
    fi
done

read -p "Are you sure that you want to remove your current gazebo version and install Gazebo$version instead? [Y/n] " answer

if test "$answer" == "n"; then
    exit
fi

echo "Installing gazebo$version.."

# remove old version
sudo apt-get remove -y gazebo* ros-indigo-gazebo*

# install from debs
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu trusty main" > /etc/apt/sources.list.d/gazebo-latest.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get install -y gazebo$version
if test "$version" == "2"; then
    sudo apt-get install -y libsdformat1
    sudo apt-get install -y ros-indigo-gazebo-ros \
    ros-indigo-gazebo-ros-control \
    ros-indigo-gazebo-plugins
else
    sudo apt-get install -y ros-indigo-gazebo$version-ros \
    #ros-indigo-gazebo$version-ros-control \
    #ros-indigo-gazebo$version-plugins
fi

sudo apt-get autoremove -y

# built/cleanup gazebo-plugins libs
cd $ROSWSS_ROOT
if test "$version" == "2"; then
    if rospack list | grep -q gazebo_plugins; then
        wstool rm external/gazebo_ros_pkgs

        # remove source
        rm -rf $ROSWSS_ROOT/src/external/gazebo_ros_pkgs

        # remove compiled binaries
        rm -rf $ROSWSS_ROOT/build/gazebo*
        rm -rf $ROSWSS_ROOT/devel/lib/gazebo*
        rm -f $ROSWSS_ROOT/devel/lib/libgazebo*
        rm -f $ROSWSS_ROOT/devel/lib/libdefault_robot_hw_sim.so
        rm -rf $ROSWSS_ROOT/devel/include/gazebo*
        rm -rf $ROSWSS_ROOT/devel/share/gazebo*
    fi
else
    if [ -z $(rospack list | grep -q gazebo_plugins)]; then
        wstool set -y -u src/external/gazebo_ros_pkgs --git https://github.com/ros-simulation/gazebo_ros_pkgs.git -v indigo-devel
    fi
fi

$ROSWSS_PREFIX make

. $ROSWSS_ROOT/setup.bash

echo ">>> Setup for Gazebo$version complete!"
