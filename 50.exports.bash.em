#!/usr/bin/env bash

export DISABLE_ROS1_EOL_WARNINGS=true

# Completions are interactive-only; skip in non-interactive build shells
# (catkin's stripped env sources this under macOS /bin/bash 3.2 and errors).
case $- in *i*) ;; *) return 0 ;; esac

# source completion files
for dir in ${ROSWSS_SCRIPTS//:/ }; do
  if [ -d "$dir/completion" ]; then
    for file in "$dir"/completion/*.sh; do
      [ -f "$file" ] || continue
      source "$file"
    done
  fi
done

# default auto completion
add_completion "clean" "_roswss_clean_complete"
add_completion "install" "_roswss_install_complete"
add_completion "make" "_catkin_pkgs_complete"
add_completion "rosdoc" "_roswss_rosdoc_complete"
add_completion "test" "_roswss_test_complete"
add_completion "ui" "_roswss_ui_complete"
add_completion "uninstall" "_roswss_uninstall_complete"
add_completion "update" "_catkin_pkgs_complete"
