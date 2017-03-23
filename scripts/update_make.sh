#!/bin/bash
set -e

$WS_SCRIPTS/update.sh
$WS_SCRIPTS/make.sh "$@"
