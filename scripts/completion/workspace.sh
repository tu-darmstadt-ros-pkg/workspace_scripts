#!/bin/bash

function roswss() {
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" = "--help" || -z "$command" ]]; then
        _roswss_help
        return 0
    fi

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        if [ -x "$dir/${command}.sh" ]; then
            $dir/${command}.sh "$@"
            return 0
        elif [ -r "$dir/${command}.sh" ]; then
            source $dir/${command}.sh "$@"
            return 0
        else
            # check if current scope is remote pc script
            for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
                if [[ "$script_name" == "$command" ]]; then
                    hostname=${script_name}_hostname
                    screen_name=${script_name}_screen_name
                    launch_command=${script_name}_launch_command
                    remote_pc "${script_name}" "${!hostname}" "${!screen_name}" "${!launch_command}" "$@"
                    return 0
                fi
            done
        fi
    done

    echo "Unknown workspace script command: $command"
    _roswss_help 

    return 1
}

function _roswss_commands() {
    local ROSWSS_COMMANDS=('help')

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        for i in `find -L $dir/ -maxdepth 1 -type f -name "*.sh"`; do
            command=${i#$dir/}
            command=${command%.sh}
            if [[ -r $i && ! " ${ROSWSS_COMMANDS[*]} " == *" $command "* ]]; then
                ROSWSS_COMMANDS+=($command)
            fi
        done
    done

    for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
        ROSWSS_COMMANDS+=($script_name)
    done
    
    echo ${ROSWSS_COMMANDS[@]}
}

function _roswss_help() {
    echo "The following commands are available:"

    commands=$(_roswss_commands)

    out=""

    for i in ${commands[@]}; do
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$i" ]]; then
                out+="\t $i \t\t (remote pc)\n"
                break
            fi
        done

        for dir in ${ROSWSS_SCRIPTS//:/ }; do
            if [ -x "$dir/$i.sh" ]; then
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

    # roswss <remote_pc> <command..>
    if [ $COMP_CWORD -eq 2 ]; then
        # check if current scope is remote pc script
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$prev" ]]; then
                _remote_pc_complete
                return
            fi
        done
    fi

    # roswss command <subcommand..>
    if [ $COMP_CWORD -ge 2 ]; then
        prev=${COMP_WORDS[1]}

        # check if current scope is remote pc script
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$prev" ]]; then
                prev=${COMP_WORDS[2]}
                break
            fi
        done

        # check for custom completion scripts
        for i in "${!ROSWSS_COMPLETION_TAGS[@]}"; do 
            if [[ "${ROSWSS_COMPLETION_TAGS[i]}" == "$prev" ]]; then
                eval ${ROSWSS_COMPLETION_SCRIPTS[$i]}
                return
            fi
        done

        # default completion
        case $prev in
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
}

complete -F _roswss_complete roswss

alias $ROSWSS_PREFIX=roswss
complete -F _roswss_complete $ROSWSS_PREFIX
