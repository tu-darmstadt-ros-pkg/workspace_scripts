#!/bin/bash

# avoid re-sourcing ROS workspace due to possible duplications in all exported path variables
#. $ROSWSS_ROOT/setup.bash ""

source $ROSWSS_BASE_SCRIPTS/completion/sim.sh

roswss_sim "$@"
