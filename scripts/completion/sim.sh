#!/bin/bash

function ws_sim() {
    world=$1

    onboard=false

    # no arguments given
    if [ -z "$world" ]; then
        world="empty"
    # help requested
    elif [[ "$world" = "--help" ]]; then
        _ws_sim_help
        return 0
    # check arguments
    else
        shift
        # onboard start request was given
        if [[ "$world" = "onboard" ]]; then
            onboard=true
            world="empty"
        # otherwise world name was given; check for onboard parameter
        elif [[ "$1" = "onboard" ]]; then
            onboard=true
            shift
        fi
    fi

    error=0

    roscd $GAZEBO_WORLDS_PKG
    if [ -z "world/${world}.world" ]; then
        echo "Unknown world file: $world"
        _ws_sim_help
        return 1
    elif [ "$onboard" = true ]; then
      roslaunch $GAZEBO_WORLDS_PKG start_onboard_all.launch world_name:=$world "$@"
    else
      roslaunch $GAZEBO_WORLDS_PKG start_all.launch world_name:=$world "$@"
    fi

    return 0
}

function _ws_sim_files() {
    local WS_WORLD_FILES=()
 
    roscd $GAZEBO_WORLDS_PKG

    for i in `find -L worlds/ -type f -name "*.world"`; do
        file=${i#worlds/}
        file=${file%.world}
        if [ -r $i ]; then
            WS_WORLD_FILES+=($file)
        fi
    done
    
    echo ${WS_WORLD_FILES[@]}
}

function _ws_sim_help() {
    echo "The following world files are available:"
    files=$(_ws_sim_files)
    for i in ${files[@]}; do
        echo "   $i"
    done

    echo "Append 'onboard' to start onboard software as well. ROS parameters has to go at the end."
}

function _ws_sim_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_ws_sim_files)" -- "$cur" ) )
    fi

    return 0
} &&
complete -F _ws_sim_complete ws_sim
