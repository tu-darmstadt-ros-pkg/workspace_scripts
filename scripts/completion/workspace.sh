#!/bin/bash

function roswss() {
    command=$1
    shift

    if [[ "$command" = "--help" || -z "$command" ]]; then
        _roswss_help
        return 0
    fi

    if [ -x "$ROSWSS_SCRIPTS/${command}.sh" ]; then
        $ROSWSS_SCRIPTS/${command}.sh "$@"
        return 0
    elif [ -r "$ROSWSS_SCRIPTS/${command}.sh" ]; then
        source $ROSWSS_SCRIPTS/${command}.sh "$@"
        return 0
    else
        echo "Unknown roswss command: $command"
        _roswss_help 
    fi

    return 1
}

function _roswss_commands() {
    local ROSWSS_COMMANDS=()

    for i in `find -L $ROSWSS_SCRIPTS/ -type f -name "*.sh"`; do
        command=${i#$ROSWSS_SCRIPTS/}
        command=${command%.sh}
        if [[ "$command" == "completion/"* || "$command" == "helper/"* ]]; then
            continue
        elif [ -r $i ]; then
            ROSWSS_COMMANDS+=($command)
        fi
    done
    
    echo ${ROSWSS_COMMANDS[@]}
}

function _roswss_help() {
    echo "The following commands are available:"

    commands=$(_roswss_commands)
    for i in ${commands[@]}; do
        if [ -x "$ROSWSS_SCRIPTS/$i.sh" ]; then
            echo "   $i"
        elif [ -r "$ROSWSS_SCRIPTS/$i.sh" ]; then
            echo "  *$i"
        fi
    done

    echo
    echo "(*) Commands marked with * may change your environment."
}

function _roswss_complete() {
    local cur
    local prev

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    # roswss <command>
    if [ $COMP_CWORD -eq 1 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W '--help' -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "$(_roswss_commands)" -- "$cur" ) )
        fi
    fi

    # roswss command <subcommand..>
    if [ $COMP_CWORD -ge 2 ]; then
        case ${COMP_WORDS[1]} in
            install)
                _roswss_install_complete
                ;;

            uninstall)
                _roswss_uninstall_complete
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
                    _roswss_sim_complete
                fi
                ;;
                
            test)
                _roswss_test_complete
                ;;

            *)
                COMPREPLY=()             
                ;;
        esac
    fi
} &&
complete -F _roswss_complete roswss

alias $ROSWSS_PREFIX=roswss
complete -F _roswss_complete $ROSWSS_PREFIX
