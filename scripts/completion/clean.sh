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
            roswss_clean_externals

            # run regular clean command
            catkin clean --all --yes

            # tidy up potential remainings
            rm -rf $ROSWSS_ROOT/build
            rm -rf $ROSWSS_ROOT/devel
            #rm -rf $ROSWSS_ROOT/.catkin_tools
            for dir in `find -L $ROSWSS_ROOT/.catkin_tools/profiles/ -maxdepth 1 -mindepth 1 -type d`; do
                rm -rf $dir/packages
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
                echo "  - externals"
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
                    roswss_clean_externals
                else
                    echo_note ">>> Cleaning package: $package"

                    # run regular clean command
                    catkin clean "$package"

                    # tidy up potential remainings
                    rm -rf $ROSWSS_ROOT/build/$package
                    rm -rf $ROSWSS_ROOT/devel/include/$package
                    rm -rf $ROSWSS_ROOT/devel/lib/$package
                    rm -rf $ROSWSS_ROOT/devel/share/$package
                    rm -rf $ROSWSS_ROOT/devel/.private/$package

                    for dir in `find -L $ROSWSS_ROOT/.catkin_tools/profiles/ -maxdepth 1 -mindepth 1 -type d`; do
                        rm -rf $dir/packages/$package
                    done

                    echoc $BLUE "Done"
                    echo
                fi
            done
            echo_info ">>> Cleaned packages."
        else
            echo_error ">>> Clean cancelled by user."
            return 1
        fi
    fi

    return 0
}

function roswss_clean_externals() {
    echo_info ">>> Cleaning externals"
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        scripts_pkg=${dir%/scripts}
        scripts_pkg=${scripts_pkg##*/}

        if [ -r "$dir/hooks/clean_externals.sh" ]; then
            echo_note "Running bash script: clean_externals.sh [$scripts_pkg]"
            . "$dir/hooks/clean_externals.sh" $@
            echoc $BLUE "Done (clean_externals.sh [$scripts_pkg])"
            echo
        fi

        if [ -d $dir/hooks/clean_externals/ ]; then
            for i in `find -L $dir/hooks/clean_externals/ -maxdepth 1 -type f -name "*.sh"`; do
                file=${i#$dir/hooks/clean_externals/}
                echo_note "Running bash script: ${file} [$scripts_pkg]"
                . "$dir/hooks/clean_externals/$file" $@
                echoc $BLUE "Done (${file} [$scripts_pkg])"
                echo
            done
        fi
    done
    echo
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
