#!/bin/bash

set -e

rosclean purge
$ROSWSS_SCRIPTS/revert.sh
$ROSWSS_SCRIPTS/update.sh
$ROSWSS_SCRIPTS/make.sh
