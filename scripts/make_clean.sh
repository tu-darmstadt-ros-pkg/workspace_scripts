#!/bin/bash
set -e

$WS_SCRIPTS/clean.sh
$WS_SCRIPTS/make.sh "$@"
