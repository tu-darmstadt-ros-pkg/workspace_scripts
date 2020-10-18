#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

#set -e

current_pwd=$PWD
cd $ROSWSS_ROOT

echo_info ">>> Making externals"
for dir in ${ROSWSS_SCRIPTS//:/ }; do
    scripts_pkg=${dir%/scripts}
    scripts_pkg=${scripts_pkg##*/}

    if [ -r "$dir/hooks/make_externals.sh" ]; then
        echo_note "Running bash script: make_externals.sh [$scripts_pkg]"
        . "$dir/hooks/make_externals.sh" $@
        echoc $BLUE "Done (make_externals.sh [$scripts_pkg])"
        echo
    fi

    if [ -d $dir/hooks/make_externals/ ]; then
        for i in `find -L $dir/hooks/make_externals/ -maxdepth 1 -type f -name "*.sh"`; do
            file=${i#$dir/hooks/make_externals/}
            echo_note "Running bash script: ${file} [$scripts_pkg]"
            . "$dir/hooks/make_externals/$file" $@
            echoc $BLUE "Done (${file} [$scripts_pkg])"
            echo
        done
    fi
done
echo

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

cd $PWD

args=${args[*]}

# add proper compile flag
if [ $debug == true ]; then
    echo
    echo "--------------------- Debug build ---------------------"
    args="-DCMAKE_BUILD_TYPE=Debug $args"
else
    echo
    echo "-------------------- Release build --------------------"
    args="-DCMAKE_BUILD_TYPE=RelWithDebInfo $args"
fi
echo ">>> Building with arguments '$args'"
echo "-------------------------------------------------------"
echo

catkin build $CATKIN_BUILD_FLAGS $args

. $ROSWSS_ROOT/setup.bash
