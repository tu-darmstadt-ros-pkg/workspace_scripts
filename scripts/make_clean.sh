#!/bin/bash

set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/clean.sh" ]; then
        $dir/clean.sh
    fi

    if [ -r "$dir/make.sh" ]; then
        $dir/make.sh "$@"
    fi
done
