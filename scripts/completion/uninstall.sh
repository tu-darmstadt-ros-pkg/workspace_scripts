#!/bin/bash

function roswss_uninstall() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    rosinstall=$1
    shift

    if [[ "$rosinstall" = "--help" || -z "$rosinstall" ]]; then
        _roswss_uninstall_help
        return 0
    fi

    # run bash script
    if [ -r "$ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh" ]; then
      $ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh "uninstall"
      error=0
    fi

    remove_from_file_exact $ROSWSS_ROOT/.install $rosinstall

    # TODO: Also uninstall packages?

    return 0
}

function _roswss_uninstall_files() {
    local ROSWSS_ROSINSTALL_FILES=()

    while read filename; do
        ROSWSS_ROSINSTALL_FILES+=($filename)
    done <$ROSWSS_ROOT/.install

    echo ${ROSWSS_ROSINSTALL_FILES[@]}
}

function _roswss_uninstall_help() {
    echo "The following optional rosinstall files are installed:"
    while read filename; do
        echo "   $filename"
    done <$ROSWSS_ROOT/.install
}

function _roswss_uninstall_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
    else
        COMPREPLY=( $( compgen -W "$(_roswss_uninstall_files)" -- "$cur" ) )
    fi

    return 0
} &&
complete -F _roswss_uninstall_complete roswss_uninstall
