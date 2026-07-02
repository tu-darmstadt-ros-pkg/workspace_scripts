#!/usr/bin/env bash

function roswss() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    local command
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" = "--help" || -z "$command" ]]; then
        if type _roswss_help >/dev/null 2>&1; then
            _roswss_help
        else
            echo_note "The following commands are available:"
            _roswss_dispatch_commands
        fi
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
            return $?
        else
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
                    return $?
                fi
            done
        fi
    done

    echo_error "Unknown workspace script command: $command"
    if type _roswss_help >/dev/null 2>&1; then
        _roswss_help
    fi

    return 1
}

function _roswss_dispatch_commands() {
    local commands
    commands=('help')

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        if [ -d $dir ]; then
            for i in "$dir"/*.sh "$dir"/*.py; do
                [ -f "$i" ] || continue
                local command
                command=${i#$dir/}
                if [[ ${command} == *.py && ! -x ${dir}/${command} ]]; then
                  continue
                fi
                command=${command%.sh}
                command=${command%.py}
                if [[ -r $i && ! " ${commands[*]} " == *" $command "* ]]; then
                    commands+=($command)
                fi
            done
        fi
    done

    for script_name in "${ROSWSS_REMOTE_PC_SCRIPTS[@]}"; do
        commands+=($script_name)
    done

    commands=( $(
      for command in "${commands[@]}"; do
          echo "$command"
      done | sort) )

    echo ${commands[@]}
}

function remote_pc() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    local script_name
    script_name="$1"
    shift

    local hostname
    hostname="$1"
    shift

    local screen_name
    screen_name="$1"
    shift

    local launch_command
    launch_command="$1"
    shift

    local command
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" == "--help" || -z "$command" ]]; then
        if type _remote_pc_help >/dev/null 2>&1; then
            _remote_pc_help
        fi
        return 0
    fi

    if [ "$command" == "ssh" ]; then
        if [ $(hostname) == "$hostname" ]; then
            echo_warn "You are already on $hostname!"
        else
            roswss ssh $hostname
        fi
    elif [[ ! $(hostname) == "$hostname" && ! "$hostname" == "localhost" ]]; then
        roswss ssh $hostname "remote_pc \"$script_name\" \"$hostname\" \"$screen_name\" \"$launch_command\" \"$command\" $@"
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

            $command "$@"
        fi
    fi

    return 0
}
