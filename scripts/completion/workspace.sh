#!/bin/bash

function rosws() {
    command=$1
    shift

    if [[ "$command" = "--help" || -z "$command" ]]; then
        _rosws_help
        return 0
    fi

    if [ -x "$ROSWS_SCRIPTS/${command}.sh" ]; then
        $ROSWS_SCRIPTS/${command}.sh "$@"
        return 0
    elif [ -r "$ROSWS_SCRIPTS/${command}.sh" ]; then
        source $ROSWS_SCRIPTS/${command}.sh "$@"
        return 0
    else
        echo "Unknown rosws command: $command"
        _rosws_help 
    fi

    return 1
}

function _rosws_commands() {
    local ROSWS_COMMANDS=()

    for i in `find -L $ROSWS_SCRIPTS/ -type f -name "*.sh"`; do
        command=${i#$ROSWS_SCRIPTS/}
        command=${command%.sh}
        if [[ "$command" == "completion/"* || "$command" == "helper/"* ]]; then
            continue
        elif [ -r $i ]; then
            ROSWS_COMMANDS+=($command)
        fi
    done
    
    echo ${ROSWS_COMMANDS[@]}
}

function _rosws_help() {
    echo "The following commands are available:"

    commands=$(_rosws_commands)
    for i in ${commands[@]}; do
        if [ -x "$ROSWS_SCRIPTS/$i.sh" ]; then
            echo "   $i"
        elif [ -r "$ROSWS_SCRIPTS/$i.sh" ]; then
            echo "  *$i"
        fi
    done

    echo
    echo "(*) Commands marked with * may change your environment."
}

function _rosws_complete() {
    local cur
    local prev

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    # rosws <command>
    if [ $COMP_CWORD -eq 1 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W '--help' -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "$(_rosws_commands)" -- "$cur" ) )
        fi
    fi

    # rosws command <subcommand..>
    if [ $COMP_CWORD -ge 2 ]; then
        case ${COMP_WORDS[1]} in
            install)
                _rosws_install_complete
                ;;

            uninstall)
                _rosws_uninstall_complete
                ;;

            launch)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $( compgen -W "--screen" -- "$cur" ) )
                fi

                COMP_WORDS=( roslaunch $ONBOARD_LAUNCH_PKG $cur )
                COMP_CWORD=2
                _roscomplete_launch
                ;;

            make|update)
                _roscomplete
                ;;

            master)
                COMPREPLY=( $( compgen -W "localhost $ROBOT_HOSTNAMES" -- "$cur" ) )
                ;;

            screen)
                COMPREPLY=( $( compgen -W "start stop show" -- "$cur" ) )
                ;;
                
            sim)
                if [ $COMP_CWORD -eq 2 ]; then
                    _rosws_sim_complete
                fi
                ;;
                
            test)
                _rosws_test_complete
                ;;

            *)
                COMPREPLY=()             
                ;;
        esac
    fi
} &&
complete -F _rosws_complete rosws

alias $ROSWS_PREFIX=rosws
complete -F _rosws_complete $ROSWS_PREFIX
