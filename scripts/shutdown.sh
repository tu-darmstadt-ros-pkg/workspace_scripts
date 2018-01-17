#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

echo -ne "${YELLOW}ARE YOU SURE TO SHUTDOWN >>> '$(hostname)' <<<? [y/N] ${NOCOLOR}"
read -N 1 REPLY
echo

if [[ "$REPLY" = "y" || "$REPLY" = "Y" ]]; then
  if screen -ls &>/dev/null ; then
    killall screen
  fi

  echo_warn "Shutting down in 3s!"
  sleep 3
  sudo shutdown -P now
else
  echo_info ">>> Shutdown request cancelled"
fi
