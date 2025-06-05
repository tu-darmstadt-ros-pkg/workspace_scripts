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
        if ! roscd "$package"; then
            echo_error "Package '$package' not found! Please check the package name and try to run a regular build first."
            return 1
        fi

        if [[ -z "$1" ]]; then
            # build and run all tests in the package
            catkin build $package -DCATKIN_ENABLE_TESTING=ON --catkin-make-args run_tests

            # get summary of test results (do not fail if there were any errors)
            set +e
            echo ""
            catkin_test_results $ROSWSS_ROOT/build/$package/test_results
            set -e
        else
            # build all tests in the package
            catkin build $package -DCATKIN_ENABLE_TESTING=ON --catkin-make-args tests

            # run requested tests manually
            for launch in "$@"; do
                rostest $text $package $launch
            done
        fi
    fi

    echo "See '$ROSWSS_ROOT/build/$package/test_results' for detailed test results."

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
