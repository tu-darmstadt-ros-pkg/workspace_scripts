#!/bin/bash
# list of valid arguments
ARGUMENTS=( "start" "stop" "show" )
ARGUMENTS_MSG="Usage: screen start/stop/show <Command>"

valid_argument () { 
    local in=1
    for element in "${ARGUMENTS[@]}"; do
        if [ $element = $1 ]; then
            return 0
        fi
    done
    return 1
}

# check if correct argument is given
if [ "$#" -eq 0 ]; then
    echo "Called with too less arguments. $ARGUMENTS_MSG"
    exit 1
elif ! valid_argument $1; then
    echo "Unknown parameter '$1'! $ARGUMENTS_MSG"
    exit 1
fi

action=$1; shift
screen_session=$1; shift

# dispatch action
case $action in
    start) # start screen
        if screen -ls | grep $screen_session; then
            echo "Error! Screen '$screen_session' is already running!"
            exit 1
        fi

        screen -dmS $screen_session /bin/bash -ic "$@"

        if screen -ls | grep $screen_session; then
            echo "Screen '$screen_session' started!"
        else
            echo "Error! Screen '$screen_session' was not started!"
            exit 1
        fi
        ;;

    stop) # stop screen
        if ! screen -ls | grep $screen_session; then
            echo "There is no screen '$screen_session' running!"
            exit 1
        fi

        screen -S $screen_session -X quit "$@"

        if screen -ls | grep $screen_session; then
            echo "Warning: The screen is maybe still running."
            exit 2
        else
            echo "Screen '$screen_session' stopped!"
        fi
        ;;

    show) # show screen
        if ! screen -ls | grep $screen_session; then
            echo "There is no screen '$screen_session' running!"
            exit 1
        fi

        screen -rx $screen_session "$@"
        ;;
esac
