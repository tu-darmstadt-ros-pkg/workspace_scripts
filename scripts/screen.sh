#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# list of valid arguments
ARGUMENTS=( "start" "stop" "show" "list" "sigterm" "graceful-stop" )
ARGUMENTS_MSG="Usage: screen start/stop/show/list/sigterm/graceful-stop <Screen Name> <Command>"

# checks if given argument is known
valid_argument() {
    local in
    in=1
    for element in "${ARGUMENTS[@]}"; do
        if [ $element = $1 ]; then
            return 0
        fi
    done
    return 1
}

# check if correct argument is given
if [ "$#" -eq 0 ]; then
    echo_error "Called with too few arguments. $ARGUMENTS_MSG"
    exit 1
elif ! valid_argument $1; then
    echo_error "Unknown parameter '$1'! $ARGUMENTS_MSG"
    exit 1
fi

action=$1; shift
screen_session=$1; shift

# dispatch action
case $action in
    start)
        if screen -ls | grep $screen_session; then
            echo_warn "Screen '$screen_session' is already running!"
            exit 1
        fi

        screen_log_dir="${ROSWSS_LOG_DIR}/screen_logs"
        max_num_screen_logs="${ROSWSS_MAX_NUM_LOGS:-25}"
        mkdir -p ${screen_log_dir}

        # only keep the most recent files
        for file in `ls -t1 -r ${screen_log_dir} | grep ${screen_session}_ | head -n -${max_num_screen_logs}`; do
            rm ${screen_log_dir}/$file
        done

        current_time=$(date "+%Y_%m_%d_%H_%M_%S")
        screen -L -Logfile ${screen_log_dir}/${screen_session}_${current_time}.log -dmS $screen_session /bin/bash -ic "$@"

        if screen -ls | grep $screen_session &>/dev/null; then
            echo_info "Screen '$screen_session' started!"
        else
            echo_warn "Screen '$screen_session' may not be started!"
            exit 1
        fi
        ;;

    stop)
        if ! screen -ls | grep $screen_session &>/dev/null; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        echo "Stopping screen '$screen_session'"
        screen -S $screen_session -X quit

        if screen -ls | grep $screen_session &>/dev/null; then
            echo_warn "Warning: The screen is maybe still running."
            exit 2
        else
            echo_info "Screen '$screen_session' stopped!"
        fi
        ;;

    show)
        if ! screen -ls | grep $screen_session &>/dev/null; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        screen -rx $screen_session "$@"
        ;;

    list)
        screen -list
        ;;

    sigterm)
        screen -S $screen_session -p 0 -X stuff "^C"
        ;;

    graceful-stop)
        if ! screen -ls | grep $screen_session &>/dev/null; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        echo "Sending SIGINT (Ctrl+C) to screen '$screen_session'"
        screen -S $screen_session -p 0 -X stuff "^C"

        # Temporary file to store screen output
        temp_file=$(mktemp)

        # Wait for the process inside the screen to terminate or for a timeout
        timeout=${1:-15}
        echo "Waiting up to $timeout seconds for screen '$screen_session' to terminate gracefully..."

        graceful_termination=false

        for ((i=0; i<timeout; i++)); do
            # Verify whether the screen session is stopped
            if ! screen -ls | grep $screen_session &>/dev/null; then
                graceful_termination=true
                break
            fi

            # Make sure the screen session is not in copy mode
            screen -S $screen_session -X eval "stuff ^["

            # Capture the current screen output to the temp file
            screen -S $screen_session -X hardcopy $temp_file

            # Check the temp file for the "=== Command terminated" message
            if grep -q "=== Command terminated" "$temp_file"; then
                graceful_termination=true
                break
            fi
            sleep 1
        done
        rm -f $temp_file  # Clean up the temp file

        if [ "$graceful_termination" = true ]; then
            echo_info "Screen '$screen_session' terminated after $i seconds gracefully."
        else
            echo_warn "Screen '$screen_session' did not terminate within the grace period, forcing to stop..."
        fi

        # Stop the screen session forcefully
        if screen -ls | grep $screen_session &>/dev/null; then
            screen -S $screen_session -X quit && sleep 0.1
        fi

        # Verify whether the screen session is stopped
        if screen -ls | grep $screen_session &>/dev/null; then
            echo_warn "Warning: The screen is maybe still running."
            exit 2
        else
            echo_info "Screen '$screen_session' session stopped! graceful=$graceful_termination"
        fi

esac
