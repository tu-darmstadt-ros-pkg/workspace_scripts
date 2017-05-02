#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/update.sh" ]; then
        $dir/update.sh
    fi

    if [ -r "$dir/make.sh" ]; then
        $dir/make.sh "$@"
    fi
done
