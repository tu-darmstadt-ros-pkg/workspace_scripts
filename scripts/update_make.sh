#!/bin/bash
set -e

$ROSWSS_SCRIPTS/update.sh
$ROSWSS_SCRIPTS/make.sh "$@"
