#!/bin/bash

function roswss_rosdoc() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    if [[ -z "$1" || "$1" = "--help" ]]; then
        _roswss_rosdoc_help
        return 0
    fi

    # install rosdoc and rosdoc_lite if required
    apt_install doxygen ros-${ROS_DISTRO}-rosdoc-lite

    # run generation
    echo_info "Generating documentation(s)..."
    echo

    for package in "$@"; do
        echo_note ">>> $package"
        roscd $package
        cd ..
        rosdoc_lite -o $package/doc $package
        echo
    done

    echo_info "Done!"

    return 0
}

function _roswss_rosdoc_help() {
    echo_note "Type name of rospackage for which the documenation should be generated."
}

function _roswss_rosdoc_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    # roswss roswss ...
    if [ $COMP_CWORD -eq 2 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
        else
            _roscomplete
        fi
    # roswss roswss $package ...
    elif [ $COMP_CWORD -ge 3 ]; then
        _roscomplete
    fi

    return 0
}
complete -F _roswss_rosdoc_complete roswss_rosdoc
