#!/bin/bash

# Call update scripts
for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/hooks/update.sh" ]; then
        . "$dir/hooks/update.sh" $@
    fi
done
