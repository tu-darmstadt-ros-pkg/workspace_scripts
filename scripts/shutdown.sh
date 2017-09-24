#!/bin/bash

echo -n "ARE YOU SURE TO SHUTDOWN >>> '$(hostname)' <<<? [y/N]"
read -N 1 REPLY

if [[ "$REPLY" = "y" || "$REPLY" = "Y" ]]; then
  killall screen
  sudo shutdown now -h
else
  echo ">>> Shutdown request cancelled"
fi
