#!/bin/bash

function roswss_install() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh
    source $ROSWSS_BASE_SCRIPTS/helper/rosinstall.sh

    local rosinstall=$1
    shift

    if [[ "$rosinstall" = "--help" || -z "$rosinstall" ]]; then
        _roswss_install_help
        return 0
    fi

    pwd=$PWD
    cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional

    # perform install
    while [[ ! -z "$rosinstall" ]]; do
        local error=1

        echo_info ">>> Installing $rosinstall"

        # perform rosinstall
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}.rosinstall" ]; then
            echo_note "Merging to workspace: ${rosinstall}.rosinstall"
            rosinstall ${rosinstall}.rosinstall
            error=0
        fi
        
        # run bash script
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}.sh" ]; then
            echo_note "Running bash script: ${rosinstall}.sh"
            source $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${rosinstall}.sh "install"
            error=0
            echoc $BLUE "DONE (${rosinstall}.sh)"
        fi

        # check error code
        if [ $error -ne 0 ]; then
            echo_error "ERROR: Unknown rosinstall file: ${rosinstall}"
            _roswss_install_help
            return 1
        fi

        # add entry in .install
        append_to_file_if_not_exist "$ROSWSS_ROOT/.install" "$rosinstall"

        rosinstall=$1
        shift
        echo
    done

    cd $pwd

    return 0
}

function _roswss_install_files() {
    local ROSWSS_ROSINSTALL_FILES=()
 
    # find all rosinstall files
    for i in `find -L $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/ -maxdepth 1 -type f -name "*.rosinstall"`; do
        local file=${i#$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/}
        file=${file%.rosinstall}
        if [ -r $i ]; then
            ROSWSS_ROSINSTALL_FILES+=($file)
        fi
    done

    # find all bash scripts
    for i in `find -L $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/ -maxdepth 1 -type f -name "*.sh"`; do
        local file=${i#$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/}
        file=${file%.sh}
        if [ -r $i ] && [ ! -f $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/$file.rosinstall ]; then
            ROSWSS_ROSINSTALL_FILES+=($file)
        fi
    done

    # sort names
    ROSWSS_ROSINSTALL_FILES=( $(
      for file in "${ROSWSS_ROSINSTALL_FILES[@]}"; do
          echo "$file"
      done | sort) )
    
    echo ${ROSWSS_ROSINSTALL_FILES[@]}
}

function _roswss_install_help() {
    echo_note "The following optional rosinstall files are available:"

    local files=$(_roswss_install_files)

    local out=""

    for i in ${files[@]}; do
        line=()

        if [ -f "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/$i.rosinstall" ]; then
            line+=(".rosinstall")
        fi
        if [ -f "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/$i.sh" ]; then
            line+=(".sh")
        fi

        out+="\t $i \t\t (${line[*]})\n"
    done

    echo -e $out | column -s $'\t' -tn
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
}
complete -F _roswss_install_complete roswss_install
