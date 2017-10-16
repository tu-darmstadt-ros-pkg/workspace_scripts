#!/bin/bash

echo -n "ARE YOU SURE TO SHUTDOWN >>> '$(hostname)' <<<? [y/N]"
read -N 1 REPLY
echo

if [[ "$REPLY" = "y" || "$REPLY" = "Y" ]]; then
  if screen -ls &>/dev/null ; then
    killall screen
  fi

  echo "Shutting down in 3s!"
  sleep 3
  sudo shutdown -P now
else
  echo ">>> Shutdown request cancelled"
fi
