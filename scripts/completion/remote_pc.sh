#!/bin/bash

function remote_pc() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

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

    if [[ "$command" == "help" || "$command" == "--help" || -z "$command" ]]; then
        _remote_pc_help
        return 0
    fi

    #echo "roswss ssh $hostname '$ROSWSS_PREFIX $script_name $command $@'"

    # check if first a ssh connection to host is required/requested
    if [ $command = 'ssh' ]; then
        if [ $(hostname) = $hostname ]; then
            echo_warn "You are already on $hostname!"
        else
            roswss ssh $hostname
        fi
    elif [ ! $(hostname) = $hostname ]; then
        roswss ssh $hostname "remote_pc '$script_name' '$hostname' '$screen_name' '$launch_command' '$command' '$@'"

    # we are on remote host pc
    else
        if [ $command == "roscore" ]; then
            roswss screen start "roscore" "roscore $@"
        elif [ $command == "start" ]; then
            roswss screen start "$screen_name" "$launch_command $@"
        elif [ $command == "stop" ]; then
            roswss screen stop "$screen_name" "$@"
        elif [ $command == "show" ]; then
            roswss screen show "$screen_name" "$@"
        else
            for dir in ${ROSWSS_SCRIPTS//:/ }; do
                if [ -x "$dir/${command}.sh" ]; then
                    roswss $command "$@"
                    return 0            
                fi
            done

            # just try to execute command when no corresponding script was found
            $command "$@"
        fi
    fi

    return 0
}

function _remote_pc_commands() {
    local COMMANDS=("roscore" "start" "stop" "show")

    commands=$(_roswss_commands)
    for i in ${commands[@]}; do

        # don't offer remote pcs again
        skip=false
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$i" ]]; then
              skip=true
              break
            fi
        done

        if [ "$skip" = true ]; then
            continue
        fi

        COMMANDS+=($i)
    done
    
    echo ${COMMANDS[@]}
}

function _remote_pc_help() {
    echo_note "The following commands are available:"

    commands=$(_remote_pc_commands)

    out=""

    for i in ${commands[@]}; do
        for dir in ${ROSWSS_SCRIPTS//:/ }; do      
            if [ $i == "roscore" ]; then
                out+="\t $i \t\t ($dir)\n"
                break
            elif [ $i == "start" ]; then
                out+="\t $i \t\t ($dir)\n"
                break
            elif [ $i == "stop" ]; then
                out+="\t $i \t\t ($dir)\n"
                break
            elif [ $i == "show" ]; then
                out+="\t $i \t\t ($dir)\n"
                break
            elif [ -x "$dir/$i.sh" ]; then
                out+="\t $i \t\t ($dir)\n"
                break
            elif [ -r "$dir/$i.sh" ]; then
                out+="* \t $i \t\t ($dir)\n"
                break
            fi
        done
    done

    echo -e $out | column -s $'\t' -tn

    echo
    echo_note "(*) Commands marked with * may change your environment."
}

function _remote_pc_complete() {
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
        COMPREPLY=( $( compgen -W "$(_remote_pc_commands)" -- "$cur" ) )
    fi
}

for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
    complete -F _remote_pc_complete $script_name
done
