#!/bin/bash

# check for .rosmaster file
if [ -f ${ROSWSS_ROOT}/.rosmaster ]; then
    roswss master "$(<${ROSWSS_ROOT}/.rosmaster)"
fi
