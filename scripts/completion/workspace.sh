#!/bin/bash

function roswss() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    local command
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" = "--help" || -z "$command" ]]; then
        _roswss_help
        return 0
    fi

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        if [ -x "$dir/${command}.sh" ]; then
            $dir/${command}.sh "$@"
            return $?
        elif [ -x "$dir/${command}.py" ]; then
            $dir/${command}.py "$@"
            return $?
        elif [ -r "$dir/${command}.sh" ]; then
            source $dir/${command}.sh "$@"
            return 0
        else
            # check if current scope is remote pc script
            for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
                if [[ "$script_name" == "$command" ]]; then
                    local pc
                    pc=${script_name}_remote_pc

                    local OLD_IFS
                    OLD_IFS=$IFS
                    IFS=$ROSWSS_SEP_SYM

                    local args
                    args=(${!pc})
                    local hostname
                    hostname=${args[1]}
                    local screen_name
                    screen_name=${args[2]}
                    local launch_command
                    launch_command=${args[3]}

                    IFS=$OLD_IFS

                    remote_pc "${script_name}" "${hostname}" "${screen_name}" "${launch_command}" "$@"
                    return 0
                fi
            done
        fi
    done

    echo_error "Unknown workspace script command: $command"
    _roswss_help 

    return 1
}

function _roswss_commands() {
    local ROSWSS_COMMANDS
    ROSWSS_COMMANDS=('help')

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        if [ -d $dir ]; then
            for i in $(find -L $dir/ -maxdepth 1 -type f -name "*.sh" -o -name "*.py"); do
                local command
                command=${i#$dir/}
                if [[ ${command} == *.py && ! -x ${dir}/${command} ]]; then
                  continue
                fi
                command=${command%.sh}
                command=${command%.py}
                if [[ -r $i && ! " ${ROSWSS_COMMANDS[*]} " == *" $command "* ]]; then
                    ROSWSS_COMMANDS+=($command)
                fi
            done
        fi
    done

    for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
        ROSWSS_COMMANDS+=($script_name)
    done

    # sort commands
    ROSWSS_COMMANDS=( $(
      for command in "${ROSWSS_COMMANDS[@]}"; do
          echo "$command"
      done | sort) )
    
    echo ${ROSWSS_COMMANDS[@]}
}

function _roswss_help() {
    echo_note "The following commands are available:"

    local commands
    commands=$(_roswss_commands)

    local out
    out=""

    for i in ${commands[@]}; do
        for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
            if [[ "$script_name" == "$i" ]]; then
                out+="\t $i \t\t (remote pc)\n"
                break
            fi
        done

        for dir in ${ROSWSS_SCRIPTS//:/ }; do  
            scripts_pkg=${dir%/scripts}
            scripts_pkg=${scripts_pkg##*/}

            if [ -x "$dir/$i.sh" ]; then
                out+="\t $i \t\t ($scripts_pkg)\n"
                break
            elif [ -x "$dir/$i.py" ]; then
                out+="\t $i \t\t ($scripts_pkg)\n"
                break
            elif [ -r "$dir/$i.sh" ]; then
                out+="* \t $i \t\t ($scripts_pkg)\n"
                break
            fi
        done
    done

    echo -e $out | column -s $'\t' -tn

    echo
    echo_note "(*) Commands marked with * may change your environment."
}

function _roswss_complete() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

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

        # check for exported completion scripts
        for i in "${!ROSWSS_COMPLETION_TAGS[@]}"; do 
            if [[ "${ROSWSS_COMPLETION_TAGS[i]}" == "$prev" ]]; then
                eval ${ROSWSS_COMPLETION_SCRIPTS[$i]}
                return
            fi
        done

        # default completion (special cases; default cases see in 50.exports.bash.em)
        case $prev in
            launch)
                # only execute if ONBOARD_LAUNCH_PKG is set
                if [ -z "$ONBOARD_LAUNCH_PKG" ]; then
                    echo
                    echo_error "ERROR: In order to use the launch command, please set ONBOARD_LAUNCH_PKG." 
                    return 1
                fi

                if [[ "$cur" == -* ]]; then
                    COMPREPLY=( $( compgen -W "--screen" -- "$cur" ) )
                fi

                COMP_WORDS=( roslaunch $ONBOARD_LAUNCH_PKG $cur )
                COMP_CWORD=2
                _roscomplete_launch
                ;;

            master)
                if [ $COMP_CWORD -eq 2 ]; then
                    COMPREPLY=( $( compgen -W "localhost $ROBOT_HOSTNAMES" -- "$cur" ) )
                fi
                ;;

            ssh)
                if [ $COMP_CWORD -eq 2 ]; then
                    COMPREPLY=( $( compgen -W "$ROBOT_HOSTNAMES" -- "$cur" ) )
                fi
                ;;

            screen)
                if [ $COMP_CWORD -eq 2 ]; then
                    COMPREPLY=( $( compgen -W "start stop show list" -- "$cur" ) )
                fi
                ;;
                
            sim)
                if [ $COMP_CWORD -eq 2 ]; then
                    _roswss_sim_complete
                fi
                ;;

            *)
                COMPREPLY=()             
                ;;
        esac
    fi
}

complete -F _roswss_complete roswss

if [[ $ROSWSS_PREFIX != "roswss" ]]; then
    alias $ROSWSS_PREFIX=roswss
    complete -F _roswss_complete $ROSWSS_PREFIX
fi
