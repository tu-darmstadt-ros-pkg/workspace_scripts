#!/bin/bash

function robot_pc() {
    script_name="$1"
    shift
    hostname="$1"
    shift
    screen_name="$1"
    shift
    launch_command="$1"
    shift
    command="$1"
    shift

    if [[ "$command" == "--help" || -z "$command" ]]; then
        _robot_pc_help
        return 0
    fi

    #echo "roswss ssh $hostname '$ROSWSS_PREFIX $script_name $command $@'"

    # check if first a ssh connection to host is required/requested
    if [ $command = 'ssh' ]; then
        if [ $(hostname) = $hostname ]; then
            echo "You are already on $hostname!"
        else
            roswss ssh $hostname
        fi
    elif [ ! $(hostname) = $hostname ]; then
        roswss ssh $hostname "robot_pc '$script_name' '$hostname' '$screen_name' '$launch_command' '$command' '$@'"

    # we are on robot host pc
    else
        if [ $command == "roscore" ]; then
            roswss screen start "roscore" "roscore $@"
        elif [ $command == "start" ]; then
            roswss screen start "$screen_name" "$launch_command $@"
        elif [ $command == "stop" ]; then
            roswss screen stop "$screen_name" "$@"
        elif [ $command == "show" ]; then
            roswss screen show "$screen_name" "$@"
        elif [ -x "$ROSWSS_SCRIPTS/${command}.sh" ]; then
            roswss $command "$@"
        else
            $command "$@"
        fi
    fi

    return 0
}

function _robot_pc_commands() {
    local COMMANDS=("roscore" "start" "stop" "show")

    commands=$(_roswss_commands)
    for i in ${commands[@]}; do
        if [ $i == "motion" ]; then
            continue
        fi
        COMMANDS+=($i)
    done
    
    echo ${COMMANDS[@]}
}

function _robot_pc_help() {
    echo "The following commands are available:"

    commands=$(_robot_pc_commands)
    for i in ${commands[@]}; do       
        if [ $i == "roscore" ]; then
            echo "   $i"
        elif [ $i == "start" ]; then
            echo "   $i"
        elif [ $i == "stop" ]; then
            echo "   $i"
        elif [ $i == "show" ]; then
            echo "   $i"
        elif [ -x "$ROSWSS_SCRIPTS/$i.sh" ]; then
            echo "   $i"
        elif [ -r "$ROSWSS_SCRIPTS/$i.sh" ]; then
            echo "  *$i"
        fi
    done

    echo
    echo "(*) Commands marked with * may change your environment."
}

function _robot_pc_complete() {
    local cur
    local prev

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_robot_pc_commands)" -- "$cur" ) )
    fi
}

for script_name in "${ROBOT_PC_SCRIPTS[@]}"; do
    complete -F _robot_pc_complete $script_name
done
