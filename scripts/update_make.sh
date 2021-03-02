#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/update.sh" ]; then
        echo  "$dir/update.sh"
        $dir/update.sh
    fi
done

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/make.sh" ]; then
        $dir/make.sh "$@"
    fi
done
