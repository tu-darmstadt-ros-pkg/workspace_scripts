#!/bin/bash
set -e

$ROSWS_SCRIPTS/clean.sh
$ROSWS_SCRIPTS/make.sh "$@"
