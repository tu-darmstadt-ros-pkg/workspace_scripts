#!/bin/bash

function roswss_test() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    set -e

    local legacy=false
    if [[ "$1" = "--fix" || "$1" = "--run_tests" ]]; then
        legacy=true
        shift
    fi
    
    local text=""
    if [[ "$1" = "--text" ]]; then
        text="--text"
        shift
    fi
  
    if [[ -z "$1" || "$1" = "--help" ]]; then
        _roswss_test_help
        return 0
    fi

    local package
    package=$1
    shift

    # build tests
    if [ $legacy = true ]; then
        echo "LEGACY"
        if [ -d "$ROSWSS_ROOT/build/$package" ]; then
            cd $ROSWSS_ROOT/build/$package
            make run_tests
        else
            echo_error "Build directory for '$package' doesn't exists (lookup path: $ROSWSS_ROOT/build/$package)! Maybe you should run a regular build first."
            return 1
        fi
    else
        roscd $package

        if [[ -z "$1" ]]; then
            catkin build $package -DCATKIN_ENABLE_TESTING=ON --catkin-make-args run_tests
        else
            catkin build $package -DCATKIN_ENABLE_TESTING=ON --catkin-make-args tests
        fi

        local launch
        launch=$1
        shift

        # run tests manually
        while [[ ! -z "$launch" ]]; do
            rostest $text $package $launch
            launch=$1
            shift
        done
    fi

    return 0
}

function _roswss_test_help() {
    echo_note "Type name of rospackage to test."
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
            COMPREPLY=( $( compgen -W "--fix --run_tests --text --help" -- "$cur" ) )
        else
            _roscomplete
        fi
    # roswss test (--legacy) $package ...
    elif [ $COMP_CWORD -eq 3 ]; then
        if [[ "${COMP_WORDS[2]}" == -* ]]; then # legacy case
          _roscomplete
        else
          COMP_WORDS=( roslaunch ${COMP_WORDS[2]} $cur )
        fi
        COMP_CWORD=2
        _roscomplete_test
    # roswss test (--legacy) $package ...
    elif [ $COMP_CWORD -ge 3 ]; then
        if [[ "${COMP_WORDS[2]}" == -* ]]; then # legacy case
          COMP_WORDS=( roslaunch ${COMP_WORDS[3]} $cur )
        else
          COMP_WORDS=( roslaunch ${COMP_WORDS[2]} $cur )
        fi
        COMP_CWORD=2
        _roscomplete_test
    fi

    return 0
}
complete -F _roswss_test_complete roswss_test
