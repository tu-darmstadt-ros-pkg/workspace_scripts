#!/bin/bash

cd $ROSWS_ROOT
catkin clean --orphans
echo " >>> If orphans were found, run '$ROSWS_PREFIX make --force-cmake' now."
