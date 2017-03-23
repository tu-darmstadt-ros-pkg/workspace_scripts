#!/bin/bash

cd $WS_ROOT
catkin clean --orphans
echo " >>> If orphans were found, run '$WS_PREFIX make --force-cmake' now."
