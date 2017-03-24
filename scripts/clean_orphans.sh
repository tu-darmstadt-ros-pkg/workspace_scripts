#!/bin/bash

cd $ROSWSS_ROOT
catkin clean --orphans
echo " >>> If orphans were found, run '$ROSWSS_PREFIX make --force-cmake' now."
