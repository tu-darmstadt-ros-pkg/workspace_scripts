#!/bin/bash

function roswss_install() {
    rosinstall=$1
    shift

    if [[ "$rosinstall" = "--help" || -z "$rosinstall" ]]; then
        _roswss_install_help
        return 0
    fi

    error=0

    # perform install
    while [[ ! -z "$rosinstall" ]]; do
        # add entry in .install
        if [ ! -f $ROSWSS_ROOT/.install ]; then
           touch $ROSWSS_ROOT/.install
        fi

        if ! grep -Fxq "${rosinstall}" $ROSWSS_ROOT/.install; then
          echo "${rosinstall}" >> $ROSWSS_ROOT/.install
        fi

        # perform install
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${rosinstall}.rosinstall" ]; then
            local LAST_PWD=$PWD
            cd $ROSWSS_ROOT/src
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
        _roswss_install_help
        return 1
    fi

    return 0
}

function _roswss_install_files() {
    local ROSWSS_ROSINSTALL_FILES=()
 
    for i in `find -L $ROSWSS_ROOT/rosinstall/optional/ -type f -name "*.rosinstall"`; do
        file=${i#$ROSWSS_ROOT/rosinstall/optional/}
        file=${file%.rosinstall}
        if [ -r $i ]; then
            ROSWSS_ROSINSTALL_FILES+=($file)
        fi
    done
    
    echo ${ROSWSS_ROSINSTALL_FILES[@]}
}

function _roswss_install_help() {
    echo "The following optional rosinstall files are available:"
    files=$(_roswss_install_files)
    for i in ${files[@]}; do
        echo "   $i"
    done
}

function _roswss_install_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_roswss_install_files)" -- "$cur" ) )
    fi

    return 0
} &&
complete -F _roswss_install_complete roswss_install
