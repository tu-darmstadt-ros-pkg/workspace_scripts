#!/bin/bash

function _catkin_pkgs_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    if [[ ${cur} == -* ]]; then
        return 0
    else
        COMPREPLY=($(compgen -W "$(_catkin_pkgs)" -- ${cur}))
    fi

    return 0
}
