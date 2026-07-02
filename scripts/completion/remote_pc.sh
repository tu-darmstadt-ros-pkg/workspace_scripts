#!/usr/bin/env bash

function _remote_pc_commands() {
    local COMMANDS
    COMMANDS=("roscore" "start" "stop" "show")

    local roswss_commands
    roswss_commands=$(_roswss_commands)

    for i in ${roswss_commands[@]}; do

        # don't offer remote pcs again
        skip=false
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$i" ]]; then
                skip=true
                break
            elif [ $i == "roscore" ]; then
                skip=true
                break
            elif [ $i == "start" ]; then
                skip=true
                break
            elif [ $i == "stop" ]; then
                skip=true
                break
            elif [ $i == "show" ]; then
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
    # Check if column command is available, install if missing
    if ! command -v column &> /dev/null; then
        echo_warn "Installing required dependency: bsdmainutils (provides 'column' command)..."
        apt_install bsdmainutils
    fi

    echo_note "The following commands are available:"

    local commands
    commands=$(_remote_pc_commands)

    local out
    out=""

    for i in ${commands[@]}; do
        for dir in ${ROSWSS_SCRIPTS//:/ }; do
            if [ $i == "roscore" ]; then
                out+="\t $i \t\t (Remote PC Script)\n"
                break
            elif [ $i == "start" ]; then
                out+="\t $i \t\t (Remote PC Script)\n"
                break
            elif [ $i == "stop" ]; then
                out+="\t $i \t\t (Remote PC Script)\n"
                break
            elif [ $i == "show" ]; then
                out+="\t $i \t\t (Remote PC Script)\n"
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
