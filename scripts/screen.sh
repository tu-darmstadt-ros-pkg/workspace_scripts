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

# Function to get the list of screens to operate on and optionally confirm
get_screens() {
    local screen_session="$1"
    local bypass_confirm="no"  # Default to requiring confirmation

    # Check if the second argument is -y or --yes to bypass confirmation
    if [[ "$2" == "-y" || "$2" == "--yes" ]]; then
        bypass_confirm="yes"  # Set to no confirmation required
    fi

    # Find all matching screen sessions that exactly match the name
    screens_to_operate=$(screen -list | grep -E "\.${screen_session}\b" | awk '{print $1}')

    if [ -z "$screens_to_operate" ]; then
        echo_info "No screens found with the name pattern '$screen_session'." >&2
        echo ''
        return 1  # Return an error code to indicate no screens found
    fi

    # Count the number of matching screens
    num_screens=$(echo "$screens_to_operate" | wc -l)

    # If more than one screen is found and confirmation is needed
    if [ "$num_screens" -gt 1 ] && [ "$bypass_confirm" = "no" ]; then
        echo "The following screen sessions will be operated on:" >&2
        echo "$screens_to_operate" >&2
        read -p "Do you want to proceed with these screens? (y/N): " user_input
        if [ "$user_input" != "y" ]; then
            echo "Aborting." >&2
            echo ''
            return 1
        fi
    fi

    # Output the list of screens only
    echo "$screens_to_operate"
    return 0  # Indicate success
}

check_screen() {
    # Check if a screen session with the exact name exists
    if screen -ls | grep -E "\.${1}\b" &>/dev/null; then
        return 0  # Screen exists
    else
        return 1  # Screen does not exist
    fi
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
        if check_screen "$screen_session"; then
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

        if check_screen "$screen_session"; then
            echo_info "Screen '$screen_session' started!"
        else
            echo_warn "Screen '$screen_session' may not be started!"
            exit 1
        fi
        ;;

    stop)
        if ! check_screen "$screen_session"; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        bypass_confirm=${1:-"no"}
        echo "Stopping screen '$screen_session'"
        get_screens "$screen_session" "$bypass_confirm" | xargs -I{} screen -S {} -X quit && sleep 0.2

        if check_screen "$screen_session"; then
            echo_warn "Warning: The screen is maybe still running."
            exit 2
        else
            echo_info "Screen '$screen_session' stopped!"
        fi
        ;;

    show)
        if ! check_screen "$screen_session"; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        screen -rx $screen_session "$@"
        ;;

    list)
        screen -list
        ;;

    sigterm)
        bypass_confirm=${1:-"no"}
        get_screens "$screen_session" "$bypass_confirm" | xargs -I{} screen -S {} -p 0 -X stuff "^C"
        ;;

    graceful-stop)
        if ! check_screen "$screen_session"; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        bypass_confirm=${1:-"no"}  # Default to confirm the action unless -y or --yes is given
        timeout=${2:-15}   # Wait for the process inside the screen to terminate or for a timeout
        sessions=$(get_screens "$screen_session" "$bypass_confirm")
        if [ $? -ne 0 ]; then
            # exit in case no screens or user aborted
            exit 1
        fi
        echo "Sending SIGINT (Ctrl+C) to screen '$screen_session'"
        echo "$sessions" | xargs -I{} screen -S {} -p 0 -X stuff "^C"

        echo "Waiting up to $timeout seconds for screen '$screen_session' to terminate gracefully..."
        # Temporary file to store screen output
        temp_file=$(mktemp)
        graceful_termination=false

        for ((i=0; i<timeout; i++)); do
            # Verify whether the screen session is stopped
            if ! check_screen "$screen_session"; then
                graceful_termination=true
                break
            fi
            sleep 1

            graceful_termination=true
            sessions=$(get_screens "$screen_session" --yes)
            for session in $sessions; do
                # Make sure the screen session is not in copy mode
                screen -S $session -X eval "stuff ^["
                # Capture the current screen output to the temp file
                screen -S $session -X hardcopy $temp_file
                # Check the temp file for the "=== Command terminated" message
                if ! grep -q "=== Command terminated" "$temp_file"; then
                    graceful_termination=false
                    break
                fi
            done
            if [ "$graceful_termination" = true ]; then
                break
            fi
        done
        rm -f $temp_file  # Clean up the temp file

        if [ "$graceful_termination" = true ]; then
            echo_info "Screen '$screen_session' terminated after $i seconds gracefully."
        else
            echo_warn "Screen '$screen_session' did not terminate within the grace period, forcing to stop..."
        fi

        # Stop the screen session(s) forcefully
        get_screens "$screen_session" --yes | xargs -I{} screen -S {} -X quit && sleep 0.2

        # Verify whether the screen session is stopped
        if check_screen "$screen_session"; then
            echo_warn "Warning: The screen is maybe still running."
            exit 2
        else
            echo_info "Screen '$screen_session' session stopped! graceful=$graceful_termination"
        fi

esac
