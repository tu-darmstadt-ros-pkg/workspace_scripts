#!/bin/bash

function roswss_test() {
    set -e
    
    package=$1
    shift

    if [[ "$package" = "--help" || -z "$package" ]]; then
        _roswss_test_help
        return 0
    fi

    if [ -d "$ROSWSS_ROOT/build/$package" ]; then
        # build tests
        roscd
        catkin build $package --catkin-make-args run_tests

        # run tests
        launch=$1
        shift
        while [[ ! -z "$launch" ]]; do
            rostest $package $launch
            launch=$1
            shift
        done

        return 0
    else
        echo "Build directory for '$package' doesn't exists! (path: $ROSWSS_ROOT/build/$package)"
    fi

    return 1
}

function _roswss_test_help() {
    echo "Type name of rospackage to test."
}

function _roswss_test_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    # roswss test ...
    if [ $COMP_CWORD -eq 2 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
        else
            _roscomplete
        fi
    # roswss test $package ...
    elif [ $COMP_CWORD -ge 3 ]; then
        COMP_WORDS=( roslaunch ${COMP_WORDS[2]} $cur )
        COMP_CWORD=2
        _roscomplete_test
    fi

    return 0
} &&
complete -F _roswss_test_complete roswss_test
