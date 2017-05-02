#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -f "$dir/update.sh" ]; then
        $dir/update.sh
    fi

    if [ -f "$dir/make.sh" ]; then
        $dir/make.sh "$@"
    fi
done
