#!/bin/bash

function rosws_install() {
    rosinstall=$1
    shift

    if [[ "$rosinstall" = "--help" || -z "$rosinstall" ]]; then
        _rosws_install_help
        return 0
    fi

    error=0

    while [[ ! -z "$rosinstall" ]]; do
        if [ -r "$ROSWS_ROOT/rosinstall/optional/${rosinstall}.rosinstall" ]; then
            local LAST_PWD=$PWD
            cd $ROSWS_ROOT/src
            wstool merge ../rosinstall/optional/${rosinstall}.rosinstall
            cd $LAST_PWD
        else
            error=1
        fi

        rosinstall=$1
        shift
    done

    if [ $error -ne 0 ]; then
        echo "Unknown rosinstall file: $rosinstall"
        _rosws_install_help
        return 1
    fi

    return 0
}

function _rosws_install_files() {
    local ROSWS_ROSINSTALL_FILES=()
 
    for i in `find -L $ROSWS_ROOT/rosinstall/optional/ -type f -name "*.rosinstall"`; do
        file=${i#$ROSWS_ROOT/rosinstall/optional/}
        file=${file%.rosinstall}
        if [ -r $i ]; then
            ROSWS_ROSINSTALL_FILES+=($file)
        fi
    done
    
    echo ${ROSWS_ROSINSTALL_FILES[@]}
}

function _rosws_install_help() {
    echo "The following rosinstall files are available:"
    files=$(_rosws_install_files)
    for i in ${files[@]}; do
        echo "   $i"
    done
}

function _rosws_install_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_rosws_install_files)" -- "$cur" ) )
    fi

    return 0
} &&
complete -F _rosws_install_complete rosws_install
