#!/bin/bash

function roswss_sim() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    world=$1

    onboard=false

    # no arguments given
    if [ -z "$world" ]; then
        world="empty"
    # help requested
    elif [[ "$world" = "--help" ]]; then
        _roswss_sim_help
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
    if [[ -z "world/${world}.world" ]]; then
        echo_error "Unknown world file: $world"
        _roswss_sim_help
        return 1
    elif [[ "$onboard" = true && ! -z "$GAZEBO_LAUNCH_W_ONBOARD_FILE" ]]; then
      roslaunch $GAZEBO_LAUNCH_PKG $GAZEBO_LAUNCH_W_ONBOARD_FILE world_name:=$world "$@"
    elif [[ ! -z "$GAZEBO_LAUNCH_FILE" ]]; then
      roslaunch $GAZEBO_LAUNCH_PKG $GAZEBO_LAUNCH_FILE world_name:=$world "$@"
    fi

    return 0
}

function _roswss_sim_files() {
    local ROSWSS_WORLD_FILES=()
 
    roscd $GAZEBO_WORLDS_PKG

    for i in `find -L worlds/ -type f -name "*.world"`; do
        file=${i#worlds/}
        file=${file%.world}
        if [ -r $i ]; then
            ROSWSS_WORLD_FILES+=($file)
        fi
    done
    
    echo ${ROSWSS_WORLD_FILES[@]}
}

function _roswss_sim_help() {
    echo_note "The following world files are available:"
    files=$(_roswss_sim_files)
    for i in ${files[@]}; do
        echo "   $i"
    done

    echo_note "Append 'onboard' to start onboard software as well. ROS parameters has to go at the end."
}

function _roswss_sim_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_roswss_sim_files)" -- "$cur" ) )
    fi

    return 0
}
complete -F _roswss_sim_complete roswss_sim
