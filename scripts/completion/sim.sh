#!/bin/bash

function roswss_sim() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    # deprecation warning
    if [ ! -z "$GAZEBO_WORLDS_PKG" ]; then
        echo
        echo_warn "Your workspace is still exporting GAZEBO_WORLDS_PKG. Please use GAZEBO_RESOURCE_PATH for models and worlds, see http://gazebosim.org/tutorials?tut=components."
    fi

    # only execute if GAZEBO_LAUNCH_PKG is set
    if [ -z "$GAZEBO_LAUNCH_PKG" ]; then
        echo_error "ERROR: In order to use the sim command, please set GAZEBO_LAUNCH_PKG." 
        return 1
    fi

    local command
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" = "--help" ]]; then
        _roswss_sim_help
        return 0
    fi

    # launch file was given
    if [[ $command == *.launch ]]; then
      shift
      roslaunch $GAZEBO_LAUNCH_PKG $command "$@"
    # use default launch file
    elif [[ ! -z "$GAZEBO_DEFAULT_LAUNCH_FILE" ]]; then
      # world was given
      if [[ $command == *.world ]]; then
        roslaunch $GAZEBO_LAUNCH_PKG $GAZEBO_DEFAULT_LAUNCH_FILE world_name:="$command" "$@"
      # neither launch nor world was given; start default
      else
        roslaunch $GAZEBO_LAUNCH_PKG $GAZEBO_DEFAULT_LAUNCH_FILE "$@"
      fi
    else
      echo_error "No GAZEBO_DEFAULT_LAUNCH_FILE is defined. Please export GAZEBO_DEFAULT_LAUNCH_FILE in your local workspace setup."
      return -1
    fi

    return 0
}

function _roswss_sim_launch_files() {
    local ROSWSS_LAUNCH_FILES
    ROSWSS_LAUNCH_FILES=()

    if [[ -z "$GAZEBO_LAUNCH_PKG" ]]; then
      return
    fi

    local path
    path="$(rospack find $GAZEBO_LAUNCH_PKG)/launch/"
 
    # find all launch files
    for i in `find -L $path -type f -name "*.launch"`; do
        file=${i#$path}
        if [ -r $i ]; then
            ROSWSS_LAUNCH_FILES+=($file)
        fi
    done
    
    echo ${ROSWSS_LAUNCH_FILES[@]}
}

function _roswss_sim_world_files() {
    local ROSWSS_WORLD_FILES
    ROSWSS_WORLD_FILES=()

    local path

    for path in ${GAZEBO_RESOURCE_PATH//:/ }; do
        if [ -d $path ]; then
            for i in `find -L $path/ -type f -name "*.world"`; do
                local file
                file=${i#$path/}
                if [ -r $i ]; then
                    ROSWSS_WORLD_FILES+=($file)
                fi
            done
        fi
    done

    echo ${ROSWSS_WORLD_FILES[@]}
}

function _roswss_sim_help() {
    local launchs
    local worlds

    echo_note "The following launch files are available:"
    launchs=$(_roswss_sim_launch_files)
    for i in ${launchs[@]}; do
        echo "   $i"
    done
    echo

    echo_note "The following worlds are available:"
    worlds=$(_roswss_sim_world_files)
    for i in ${worlds[@]}; do
        echo "   $i"
    done
    echo
}

function _roswss_sim_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [ $COMP_CWORD -eq 2 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "$(_roswss_sim_launch_files) $(_roswss_sim_world_files)" -- "$cur" ) )
        fi
    fi

    return 0
}
complete -F _roswss_sim_complete roswss_sim
