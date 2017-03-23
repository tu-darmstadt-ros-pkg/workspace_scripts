#!/bin/bash

function ws() {
    command=$1
    shift

    if [[ "$command" = "--help" || -z "$command" ]]; then
        _ws_help
        return 0
    fi

    if [ -x "$WS_SCRIPTS/${command}.sh" ]; then
        $WS_SCRIPTS/${command}.sh "$@"
        return 0
    elif [ -r "$WS_SCRIPTS/${command}.sh" ]; then
        source $WS_SCRIPTS/${command}.sh "$@"
        return 0
    else
        echo "Unknown ws command: $command"
        _ws_help 
    fi

    return 1
}

function _ws_commands() {
    local WS_COMMANDS=()

    for i in `find -L $WS_SCRIPTS/ -type f -name "*.sh"`; do
        command=${i#$WS_SCRIPTS/}
        command=${command%.sh}
        if [[ "$command" == "completion/"* || "$command" == "helper/"* ]]; then
            continue
        elif [ -r $i ]; then
            WS_COMMANDS+=($command)
        fi
    done
    
    echo ${WS_COMMANDS[@]}
}

function _ws_help() {
    echo "The following commands are available:"

    commands=$(_ws_commands)
    for i in ${commands[@]}; do
        if [ -x "$WS_SCRIPTS/$i.sh" ]; then
            echo "   $i"
        elif [ -r "$WS_SCRIPTS/$i.sh" ]; then
            echo "  *$i"
        fi
    done

    echo
    echo "(*) Commands marked with * may change your environment."
}

function _ws_complete() {
    local cur
    local prev

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur prev

    # ws <command>
    if [ $COMP_CWORD -eq 1 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W '--help' -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "$(_ws_commands)" -- "$cur" ) )
        fi
    fi

    # ws command <subcommand..>
    if [ $COMP_CWORD -ge 2 ]; then
        case ${COMP_WORDS[1]} in
            install)
                _ws_install_complete
                ;;

            uninstall)
                _ws_uninstall_complete
                ;;

            launch)
                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $( compgen -W "--screen" -- "$cur" ) )
                fi

                COMP_WORDS=( roslaunch ws_mang_onboard_launch $cur )
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
                    _ws_sim_complete
                fi
                ;;
                
            test)
                _ws_test_complete
                ;;

            *)
                COMPREPLY=()             
                ;;
        esac
    fi
} &&
complete -F _ws_complete ws

alias $WS_PREFIX=ws
complete -F _ws_complete $WS_PREFIX
