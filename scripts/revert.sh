#!/bin/bash
# By Christian Steiger

set -e -u

echo "Check and revert repositories..."
cd $ROSWSS_ROOT
repos=$(wstool | grep -E "(MV|M |V |M|V) git  master" | awk '{print $1, $4}' | tr ' ' '#' | tr '\n' ' ')

for repo in $repos
do
    echo "Reverting repository ${repo%%#*}..."
    cd ${repo%%#*}
    git reset --hard
    git checkout ${repo##*#}
    cd -
done

echo
echo "Checking and reverting repositories finished."
echo
