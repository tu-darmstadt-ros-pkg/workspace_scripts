#!/bin/bash

# avoid re-sourcing ROS workspace due to possible duplications in all exported path variables
#. $ROSWSS_ROOT/setup.bash ""

source $ROSWSS_BASE_SCRIPTS/completion/clean.sh

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/hooks/clean_externals.sh" ]; then
        . "$dir/hooks/clean_externals.sh" $@
    fi
done

roswss_clean "$@"
