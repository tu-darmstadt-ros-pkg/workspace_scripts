#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -f "$dir/clean.sh" ]; then
        $dir/clean.sh
    fi

    if [ -f "$dir/make.sh" ]; then
        $dir/make.sh "$@"
    fi
done
