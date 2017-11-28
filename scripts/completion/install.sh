#!/bin/bash

function roswss_install() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    rosinstall=$1
    shift

    if [[ "$rosinstall" = "--help" || -z "$rosinstall" ]]; then
        _roswss_install_help
        return 0
    fi

    # perform install
    while [[ ! -z "$rosinstall" ]]; do
        error=1

        # perform rosinstall
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${rosinstall}.rosinstall" ]; then
          echo "Merging to workspace: ${filename}.rosinstall"
          local LAST_PWD=$PWD
          cd $ROSWSS_ROOT/src
          wstool merge ../rosinstall/optional/${rosinstall}.rosinstall
          cd $LAST_PWD
          error=0
        fi
        
        # run bash script
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh" ]; then
          echo "[Running bash script: ${filename}.sh]"
          $ROSWSS_ROOT/rosinstall/optional/${rosinstall}.sh "install"
          error=0
        fi

        # check error code
        if [ $error -ne 0 ]; then
            echo "ERROR: Unknown rosinstall file: $rosinstall"
            _roswss_install_help
            return 1
        fi

        # add entry in .install
        append_to_file_if_not_exist "$ROSWSS_ROOT/.install" "$rosinstall"

        rosinstall=$1
        shift
    done

    return 0
}

function _roswss_install_files() {
    local ROSWSS_ROSINSTALL_FILES=()
 
    # find all rosinstall files
    for i in `find -L $ROSWSS_ROOT/rosinstall/optional/ -type f -name "*.rosinstall"`; do
        file=${i#$ROSWSS_ROOT/rosinstall/optional/}
        file=${file%.rosinstall}
        if [ -r $i ]; then
            ROSWSS_ROSINSTALL_FILES+=($file)
        fi
    done

    # find all bash scripts
    for i in `find -L $ROSWSS_ROOT/rosinstall/optional/ -type f -name "*.sh"`; do
        file=${i#$ROSWSS_ROOT/rosinstall/optional/}
        file=${file%.sh}
        if [ -r $i ] && [ ! -f $ROSWSS_ROOT/rosinstall/optional/$file.rosinstall ]; then
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
    echo "The following optional rosinstall files are available:"

    files=$(_roswss_install_files)

    out=""

    for i in ${files[@]}; do
        line=()

        if [ -f "$ROSWSS_ROOT/rosinstall/optional/$i.rosinstall" ]; then
            line+=(".rosinstall")
        fi
        if [ -f "$ROSWSS_ROOT/rosinstall/optional/$i.sh" ]; then
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
