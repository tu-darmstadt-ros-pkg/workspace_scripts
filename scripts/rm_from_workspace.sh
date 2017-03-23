#!/bin/bash

# This script is for simultaneously removing a folder from the workspace and then directly deleting
# it afterwards. It also checks for existence of the folder, so this script can be used without
# generating errors when folder does not exist. It has to be called from a valid workspace folder
# (rosbuild_ws or catkin_ws in our case)

if [ -d "$1" ]; then
  wstool rm $1
  rm $1 -rf
  echo "Removed folder $1 from workspace."
fi
