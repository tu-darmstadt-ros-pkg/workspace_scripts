#!/bin/bash

function roswss_uninstall() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    if [[ "$1" = "--help" || -z "$1" ]]; then
        _roswss_uninstall_help
        return 0
    fi

    # perform install
    local rosinstall
    for rosinstall in "$@"; do
    
        echo_info ">>> Uninstalling $rosinstall"
        
        # run bash script
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh" ]; then
            echo_note "Running bash script: ${rosinstall}.sh"
            $ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh "uninstall"
            echoc $BLUE "Done (${rosinstall}.sh)"
            echo
        fi

        remove_from_file_exact "$ROSWSS_ROOT/.install" "$rosinstall"

        # TODO: Also uninstall packages?
    done

    return 0
}

function _roswss_uninstall_files() {
    local ROSWSS_ROSINSTALL_FILES
    ROSWSS_ROSINSTALL_FILES=()

    while read filename; do
        ROSWSS_ROSINSTALL_FILES+=($filename)
    done <$ROSWSS_ROOT/.install

    # sort names
    ROSWSS_ROSINSTALL_FILES=( $(
      for file in "${ROSWSS_ROSINSTALL_FILES[@]}"; do
          echo "$file"
      done | sort) )

    echo ${ROSWSS_ROSINSTALL_FILES[@]}
}

function _roswss_uninstall_help() {
    echo_note "The following optional rosinstall files are installed:"

    local files
    files=$(_roswss_install_files)

    for i in ${files[@]}; do
        echo "   $i"
    done
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
}
complete -F _roswss_uninstall_complete roswss_uninstall
