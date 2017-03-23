#!/bin/bash
sudo /etc/init.d/chrony stop
if [ "$#" -lt 1 ]; then
  sudo ntpdate $ROBOT_MASTER_HOSTNANE
else
  sudo ntpdate $1
fi
  sudo /etc/init.d/chrony start
  
