#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

# list of valid arguments
ARGUMENTS=( "start" "stop" "show" "list" )
ARGUMENTS_MSG="Usage: screen start/stop/show/list <Screen Name> <Command>"

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
    echo_error "Called with too less arguments. $ARGUMENTS_MSG"
    exit 1
elif ! valid_argument $1; then
    echo_error "Unknown parameter '$1'! $ARGUMENTS_MSG"
    exit 1
fi

action=$1; shift
screen_session=$1; shift

# dispatch action
case $action in
    start) # start screen
        if screen -ls | grep $screen_session; then
            echo_warn "Screen '$screen_session' is already running!"
            exit 1
        fi

        # create subfolders for each screen, there seems to be no option to change the output file name
        mkdir -p ${ROSWSS_LOG_DIR}/screen_logs/$screen_session
        cd ${ROSWSS_LOG_DIR}/screen_logs/$screen_session
        [ -f screenlog.0 ] && rm screenlog.0
        screen -dmLS $screen_session /bin/bash -ic "$1 $2 $3 $4 $5"

        if screen -ls | grep $screen_session &>/dev/null; then
            echo_info "Screen '$screen_session' started!"
        else
            echo_warn "Screen '$screen_session' may not be started!"
            exit 1
        fi
        ;;

    stop) # stop screen
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

    show) # show screen
        if ! screen -ls | grep $screen_session &>/dev/null; then
            echo_error "There is no screen '$screen_session' running!"
            exit 1
        fi

        screen -rx $screen_session "$@"
        ;;

    list)
        screen -list
        ;;
esac
