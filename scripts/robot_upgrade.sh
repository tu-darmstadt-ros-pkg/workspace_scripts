#!/bin/bash

set -e

rosclean purge

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -f "$dir/revert.sh" ]; then
        $dir/revert.sh
    fi

    if [ -f "$dir/update.sh" ]; then
        $dir/update.sh
    fi

    if [ -f "$dir/make.sh" ]; then
        $dir/make.sh
    fi
done
