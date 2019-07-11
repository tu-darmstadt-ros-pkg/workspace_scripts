#!/bin/bash

. $ROSWSS_ROOT/setup.bash

versions="7, 8, 9"

valid_version=false

sudo echo

version=$1
if [[ $version ]]; then
  if [[ $versions =~ $version ]]; then
    valid_version=true
  fi
fi

while [ $valid_version = false ]; do
  read -p "Which version of Gazebo do you want to install (7, 8, 9)?" version
  if [[ $versions =~ $version ]]; then
    valid_version=true
  else
    echo "Invalid Gazebo version number."
  fi
done

read -p "Are you sure that you want to remove your current gazebo version and install Gazebo$version instead? [Y/n] " answer

if test "$answer" == "n"; then
  exit
fi

echo "Installing gazebo$version.."

# remove old version
if [ $(dpkg-query -W -f='${Status}' gazebo$version 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get remove -y gazebo* ros-$ROS_DISTRO-gazebo*
fi

# install from debs
sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu xenial main" > /etc/apt/sources.list.d/gazebo-latest.list'
wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
sudo apt-get update

sudo apt-get install -y gazebo$version
if test "$version" == "7"; then
  sudo apt-get install -y ros-$ROS_DISTRO-gazebo-ros \
  ros-$ROS_DISTRO-gazebo-ros-control \
  ros-$ROS_DISTRO-gazebo-plugins
else
  sudo apt-get install -y ros-$ROS_DISTRO-gazebo$version-ros \
  ros-$ROS_DISTRO-gazebo$version-ros-control \
  ros-$ROS_DISTRO-gazebo$version-plugins
fi

sudo apt-get autoremove -y

# built/cleanup gazebo-plugins libs
cd $ROSWSS_ROOT
if [ -z $(rospack list | grep -q gazebo_plugins)]; then
  wstool set -y -u src/external/gazebo_ros_pkgs --git https://github.com/ros-simulation/gazebo_ros_pkgs.git -v $ROS_DISTRO-devel
fi

roswss make

. $ROSWSS_ROOT/setup.bash

echo ">>> Setup for Gazebo$version complete!"
