#!/bin/bash

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/update.sh" ]; then
        $dir/update.sh
        break
    fi
done

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/make.sh" ]; then
        $dir/make.sh "$@"
        break
    fi
done
