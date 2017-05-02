#!/bin/bash

set -e

rosclean purge

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/revert.sh" ]; then
        $dir/revert.sh
    fi

    if [ -r "$dir/update.sh" ]; then
        $dir/update.sh
    fi

    if [ -r "$dir/make.sh" ]; then
        $dir/make.sh
    fi
done
