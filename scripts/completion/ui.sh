#!/bin/bash

function roswss_ui() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    # only execute if UI_LAUNCH_PKG is set
    if [ -z "$UI_LAUNCH_PKG" ]; then
        echo_error "ERROR: In order to use the ui command, please set UI_LAUNCH_PKG."
        return 1
    fi

    local command
    command="$1"
    shift

    if [[ "$command" == "help" || "$command" = "--help" ]]; then
        _roswss_ui_help
        return 0
    fi

    if [[ -z "$command" ]]; then
      if [[ -z "$UI_DEFAULT_LAUNCH_FILE" ]]; then
        _roswss_ui_help
        return 0
      else
        roslaunch $UI_LAUNCH_PKG $UI_DEFAULT_LAUNCH_FILE "$@"
        return 0
      fi
    fi

    local path
    path="$(rospack find $UI_LAUNCH_PKG)"

    local config

    if [[ "$command" == "rqt" ]]; then
        if [[ -n "$1" ]]; then
            config="$1"
            shift
            roslaunch $UI_LAUNCH_PKG rqt.launch rqt_perspective_path:=${path}/config/rqt/${config}.perspective "$@"
        else
            roslaunch $UI_LAUNCH_PKG rqt.launch "$@"
        fi
        return 0
    elif [[ "$command" == "rviz" ]]; then
        if [[ -n "$1" ]]; then
            config="$1"
            shift
            roslaunch $UI_LAUNCH_PKG rviz.launch rviz_profile_path:=${path}/config/rviz/${config}.rviz "$@"
        else
            roslaunch $UI_LAUNCH_PKG rviz.launch "$@"
        fi
        return 0
    elif [[ "$command" == "plotjuggler" ]]; then
        if [[ -n "$1" ]]; then
            config="$1"
            shift
            roslaunch $UI_LAUNCH_PKG plotjuggler.launch plotjuggler_layout_path:=${path}/config/plotjuggler/${config}.xml "$@"
        else
            roslaunch $UI_LAUNCH_PKG plotjuggler.launch "$@"
        fi
        return 0
    else
      roslaunch $UI_LAUNCH_PKG ${command}.launch "$@"
      return 0
    fi

    echo_error "Unknown command: $command"
    _roswss_ui_help
}

function _roswss_ui_launch_files() {
    local LAUNCH_FILES
    LAUNCH_FILES=()

    local path
    path="$(rospack find $UI_LAUNCH_PKG)/launch/"

    # find all launch files
    for i in `find -L $path -type f -name "*.launch"`; do
        local file
        file=${i#$path}
        file=${file%.launch}
        if [ -r $i ]; then
            LAUNCH_FILES+=($file)
        fi
    done

    echo ${LAUNCH_FILES[@]}
}

function _roswss_ui_rqt_config_files() {
    local CONFIG_FILES
    CONFIG_FILES=()

    local path
    path="$(rospack find $UI_LAUNCH_PKG)/config/rqt/"

    # check if path exists
    if [ -d "$path" ]; then
      # find all rqt perspective files
      for i in `find -L $path -type f -name "*.perspective"`; do
          local file
          file=${i#$path}
          file=${file%.perspective}
          if [ -r $i ]; then
              CONFIG_FILES+=($file)
          fi
      done
    fi

    echo ${CONFIG_FILES[@]}
}

function _roswss_ui_rviz_config_files() {
    local CONFIG_FILES
    CONFIG_FILES=()

    local path
    path="$(rospack find $UI_LAUNCH_PKG)/config/rviz/"

    # check if path exists
    if [ -d "$path" ]; then
      # find all rviz files
      for i in `find -L $path -type f -name "*.rviz"`; do
          local file
          file=${i#$path}
          file=${file%.rviz}
          if [ -r $i ]; then
              CONFIG_FILES+=($file)
          fi
      done
    fi

    echo ${CONFIG_FILES[@]}
}

function _roswss_ui_plotjuggler_layout_files() {
    local CONFIG_FILES
    CONFIG_FILES=()

    local path
    path="$(rospack find $UI_LAUNCH_PKG)/config/plotjuggler/"

    # check if path exists
    if [ -d "$path" ]; then
      # find all plotjuggler layout files
      for i in `find -L $path -type f -name "*.xml"`; do
          local file
          file=${i#$path}
          file=${file%.xml}
          if [ -r $i ]; then
              CONFIG_FILES+=($file)
          fi
      done
    fi

    echo ${CONFIG_FILES[@]}
}

function _roswss_ui_commands() {
    local ROSWSS_COMMANDS
    ROSWSS_COMMANDS=('help' 'rqt' 'rviz' 'plotjuggler')

    echo ${ROSWSS_COMMANDS[@]}
}

function _roswss_ui_help() {
    local commands

    commands=$(_roswss_ui_commands)
    echo_note "The following commands are available:"
    for i in ${commands[@]}; do
        echo "   $i"
    done
    echo

    commands=$(_roswss_ui_launch_files)
    if [ -n "$commands" ]; then
        echo_note "The following launch files are available:"
        for i in ${commands[@]}; do
            echo "   $i"
        done
        echo
    fi

    commands=$(_roswss_ui_rqt_config_files)
    if [ -n "$commands" ]; then
        echo_note "The following rqt perspectives are available:"
        for i in ${commands[@]}; do
            echo "   $i"
        done
        echo
    fi

    commands=$(_roswss_ui_rviz_config_files)
    if [ -n "$commands" ]; then
        echo_note "The following rviz defaults are available:"
        for i in ${commands[@]}; do
            echo "   $i"
        done
    fi

    commands=$(_roswss_ui_plotjuggler_layout_files)
    if [ -n "$commands" ]; then
        echo_note "The following plotjuggler layouts are available:"
        for i in ${commands[@]}; do
            echo "   $i"
        done
        echo
    fi
}

function _roswss_ui_complete() {
    source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

    # only execute if UI_LAUNCH_PKG is set
    if [ -z "$UI_LAUNCH_PKG" ]; then
        echo
        echo_error "ERROR: In order to use the ui command, please set UI_LAUNCH_PKG."
        return 1
    fi

    local cur
    local prev

    if ! type _get_comp_words_by_ref >/dev/null 2>&1; then
        return 0
    fi

    COMPREPLY=()
    _get_comp_words_by_ref cur

    # ui <command>
    if [ $COMP_CWORD -eq 2 ]; then
        if [[ "$cur" == -* ]]; then
            COMPREPLY=( $( compgen -W "--help" -- "$cur" ) )
        else
            COMPREPLY=( $( compgen -W "$(_roswss_ui_commands) $(_roswss_ui_launch_files)" -- "$cur" ) )
        fi
    fi

    # rqt/rviz command <subcommand..>
    if [ $COMP_CWORD -eq 3 ]; then
        prev=${COMP_WORDS[2]}

        # default completion
        case $prev in
            rqt)
                COMPREPLY=( $( compgen -W "$(_roswss_ui_rqt_config_files)" -- "$cur" ) )
                ;;

            rviz)
                COMPREPLY=( $( compgen -W "$(_roswss_ui_rviz_config_files)" -- "$cur" ) )
                ;;

            plotjuggler)
                COMPREPLY=( $( compgen -W "$(_roswss_ui_plotjuggler_layout_files)" -- "$cur" ) )
                ;;

            *)
                COMPREPLY=()
                ;;
        esac
    fi

    return 0
}
complete -F _roswss_ui_complete roswss_ui
