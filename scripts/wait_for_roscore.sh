#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

echo_note "Waiting for roscore to start up..."
until rostopic list &>/dev/null ; do sleep 1; done
echo_info "Roscore found."
