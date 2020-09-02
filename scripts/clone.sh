#!/bin/bash

source $ROSWSS_ROOT/setup.bash ""
source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

REPO_URL=""
REPO_DIRECTORY=""
PARAMS=()

for arg in $@; do
  # Ignore git options
  if [[ "$arg" = -* ]]; then
    PARAMS+=("$arg")
    continue
  fi
  if [ -z "${REPO_URL}" ]; then
    REPO_URL="$arg"
  else
    PARAMS+=("$arg")
  fi
done

if [ -z "${REPO_URL}" ]; then
  echo_error "No url provided!"
  echo "Usage: ${ROSWSS_PREFIX} clone GIT_URL [WSTOOL_OPTIONS]"
  echo "Example: ${ROSWSS_PREFIX} clone https://github.com/tu-darmstadt-ros-pkg/workspace_scripts.git -v melodic-devel"
  exit 1
fi

if [ -z "$REPO_DIRECTORY" ]; then
  REPO_DIRECTORY=$(basename "${REPO_URL}" .git)
fi

cd $ROSWSS_ROOT
wstool set "src/${REPO_DIRECTORY}" --git "${REPO_URL}" ${PARAMS[@]}
wstool update "src/${REPO_DIRECTORY}"
