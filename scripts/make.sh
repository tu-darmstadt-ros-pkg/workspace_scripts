#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# TODO: use getopts

build_debug=false
build_this=false
build_externals=false
build_cores=$(echo "$@" | grep -oP 'j\s*\K\d+')

# get number of cores
if [ -z $build_cores ]; then
    build_cores=$(nproc --all)
fi

# check arguments
catkin_args=()
for var in "$@"; do
    case $var in
        debug)
            build_debug=true
            ;;
        --this)
            build_this=true
            catkin_args=( "${catkin_args[@]}" "$var" )
            ;;
        --externals)
            build_externals=true
            ;;
        --distcc)
            catkin_args=( "${catkin_args[@]}" "-p$(distcc -j) -j$(distcc -j) --no-jobserver" )
            ;;
        *)
            args=$(catkin list -u | sed -n "/$var/p" | tr '\n' ' ') # get package(s) from catkin list
            [[ -z "$args" ]] && args="$var" # if no package found, use argument as is
            catkin_args=( "${catkin_args[@]}" "${args}" )
            ;;
    esac
done
catkin_args=${catkin_args[*]}

LAST_PWD=$PWD

# run pre-build options
cd "$ROSWSS_ROOT"
if [[ $build_externals = true || $build_this = false ]]; then
    # call external build scripts
    echo_info ">>> Making externals"
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        scripts_pkg=${dir%/scripts}
        scripts_pkg=${scripts_pkg##*/}

        if [ -r "$dir/hooks/make_externals.sh" ]; then
            echo_note "Running bash script: make_externals.sh [$scripts_pkg]"
            . "$dir/hooks/make_externals.sh" "$@"
            echoc $BLUE "Done (make_externals.sh [$scripts_pkg])"
            echo
        fi

        if [ -d $dir/hooks/make_externals/ ]; then
            for i in `find -L $dir/hooks/make_externals/ -maxdepth 1 -type f -name "*.sh"`; do
                file=${i#$dir/hooks/make_externals/}
                echo_note "Running bash script: ${file} [$scripts_pkg]"
                . "$dir/hooks/make_externals/$file" "$@"
                echoc $BLUE "Done (${file} [$scripts_pkg])"
                echo
            done
        fi
    done
    echo

    # clean removed or disabled packages
    if [ -d $ROSWSS_ROOT/.catkin_tools ]; then
        # check devel space layout
        layout=$(catkin config | grep "Devel Space Layout:" | awk '{print $NF}')
        if [ $layout = "linked" ]; then
            catkin clean --orphans
        fi
    fi
fi

# change directory back for --this flag
if [ $build_this = true ]; then
    cd "$LAST_PWD"
fi

# Set the memory limit on machines when building with more than 8 cores
mem_limit_arg=""
if [ $build_cores -gt 8 ]; then
    mem_limit_arg="--mem-limit 80%"
fi

# run catkin main build process
if [[ $build_this = true || $build_externals = false ]]; then
    if [ $build_debug = true ]; then
        echo
        echo "--------------------- Debug build ---------------------"
        catkin_args="-DCMAKE_BUILD_TYPE=Debug $catkin_args"
    else
        echo
        echo "-------------------- Release build --------------------"
        catkin_args="-DCMAKE_BUILD_TYPE=RelWithDebInfo $catkin_args"
    fi
    echo ">>> Building with arguments '$catkin_args'"
    echo "-------------------------------------------------------"
    echo

    catkin build $CATKIN_BUILD_FLAGS $mem_limit_arg $catkin_args
fi

. $ROSWSS_ROOT/setup.bash
