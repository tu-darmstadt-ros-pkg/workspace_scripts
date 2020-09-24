#!/bin/bash

set -e

current_pwd=$PWD

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/hooks/make_externals.sh" ]; then
        . "$dir/hooks/make_externals.sh"
    fi
done

cd "$current_pwd"

# TODO: use getopts

# check if debug compile is set
args=("$@")
debug=false
for (( i=0; i<${#args[@]}; i++ )); do
    var=${args[i]}
    if [ "$var" == "debug" ]; then
        debug=true
        args=( "${args[@]:0:$i}" "${args[@]:$((i + 1))}" )
        break
    fi
done

# check for single pkg compile
change_dir=true
for var in $args; do
    if [ "$var" == "--this" ]; then
        change_dir=false
        break
    fi
done

if [ $change_dir == true ]; then
    cd $ROSWSS_ROOT

    # clean removed or disabled packages
    if [ -d $ROSWSS_ROOT/.catkin_tools ]; then
        catkin clean --orphans
    fi
fi

echo $PWD

args=${args[*]}

# add proper compile flag
if [ $debug == true ]; then
    echo
    echo "-------------------- Debug build --------------------"
    args="-DCMAKE_BUILD_TYPE=Debug $args"
else
    echo
    echo "------------------- Release build -------------------"
    args="-DCMAKE_BUILD_TYPE=Release $args"
fi
echo ">>> Building with arguments '$args'"
echo "-----------------------------------------------------"
echo

catkin build -c $args

. $ROSWSS_ROOT/setup.bash
