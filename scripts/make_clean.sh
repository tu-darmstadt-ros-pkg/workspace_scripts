#!/bin/bash
set -e

$ROSWSS_SCRIPTS/clean.sh
$ROSWSS_SCRIPTS/make.sh "$@"
