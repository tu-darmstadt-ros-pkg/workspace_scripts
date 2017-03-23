#!/bin/bash
set -e

$ROSWS_SCRIPTS/update.sh
$ROSWS_SCRIPTS/make.sh "$@"
