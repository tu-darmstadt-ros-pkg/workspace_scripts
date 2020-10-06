#!/bin/bash

function roswss_clean() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    if [[ "$1" = "--help" ]]; then
        _roswss_clean_help
        return 0
    fi

    cd $ROSWSS_ROOT

    if [ "$#" -eq 0 ]; then
        echo -ne "${YELLOW}Do you want to clean build, devel and install? [y/N] ${NOCOLOR}"
        read -N 1 REPLY

        if test "$REPLY" = "y" -o "$REPLY" = "Y"; then
            echo
            echo
            catkin clean --all --yes
            for dir in ${ROSWSS_SCRIPTS//:/ }; do
                if [ -f "$dir/hooks/clean_externals.sh" ]; then
                    . $dir/hooks/clean_externals.sh
                fi
            done
            echo_info ">>> Cleaned devel and build directories."
        else
            echo_error ">>> Clean cancelled by user."
            return 1
        fi
    else
        echo_warn "Do you want to clean following packages:"
        for package in "$@"; do
            if [ $package == "--externals" ]; then
                echo "  - external libraries (calls clean_externals.sh)"
            else
                echo "  - $package"
            fi
        done
        echo -ne "${YELLOW}[y/N] ${NOCOLOR}"
        read -N 1 REPLY

        if test "$REPLY" = "y" -o "$REPLY" = "Y"; then
            echo
            echo
            for package in "$@"; do
                if [ $package == "--externals" ]; then
                    for dir in ${ROSWSS_SCRIPTS//:/ }; do
                        if [ -f "$dir/hooks/clean_externals.sh" ]; then
                             . $dir/hooks/clean_externals.sh
                        fi
                    done
                else
                    echo_note ">>> Cleaning package: $package"
                    catkin clean "$package"
                    echoc $BLUE "Done"
                fi
                echo
            done
            echo_info ">>> Cleaned packages."
        else
            echo_error ">>> Clean cancelled by user."
            return 1
        fi
    fi

    return 0
}

function _roswss_clean_help() {
    echo_note "Type name of rospackage to clean."
}

function _roswss_clean_complete() {
    local cur

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    # roswss clean ...
    if [ $COMP_CWORD -eq 2 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "--help --externals" -- "$cur" ) )
        else
            _roscomplete
        fi
    # roswss clean (--legacy) $package ...
    elif [ $COMP_CWORD -eq 3 ]; then
        if [[ "${COMP_WORDS[2]}" == -* ]]; then # legacy case
          _roscomplete
        else
          COMP_WORDS=( roslaunch ${COMP_WORDS[2]} $cur )
        fi
        COMP_CWORD=2
        _roscomplete
    # roswss clean (--legacy) $package ...
    elif [ $COMP_CWORD -ge 3 ]; then
        if [[ "${COMP_WORDS[2]}" == -* ]]; then # legacy case
          COMP_WORDS=( roslaunch ${COMP_WORDS[3]} $cur )
        else
          COMP_WORDS=( roslaunch ${COMP_WORDS[2]} $cur )
        fi
        COMP_CWORD=2
        _roscomplete
    fi

    return 0
}
complete -F _roswss_clean_complete roswss_clean
