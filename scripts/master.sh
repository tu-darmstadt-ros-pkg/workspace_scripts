#!/bin/bash

master=$1
#host -t a $master >/dev/null
#if [ "$?" -ne 0 ]; then
#    echo "WARNING! Host $master cannot be resolved at the moment!"
#fi

# export ROS_MASTER_URI
export ROS_MASTER_URI=http://$master:11311
echo "Setting ROS_MASTER_URI to $ROS_MASTER_URI"

# export ROS_IP
if [ -n "$2" ]; then
    export ROS_IP=$2
    echo "Setting ROS_IP to $ROS_IP"
fi

if [ -n "$ROS_IP" ]; then return; fi
echo

# Some informations
hostname=$HOSTNAME
if [ -n "$ROS_HOSTNAME" ]; then hostname=$ROS_HOSTNAME; fi

myips=$(hostname -I)
echo -n "Your hostname is: "; host -t a $hostname
if [ $? -eq 0 ]; then
    echo "If this address is not reachable from the master, you need to set the ROS_IP environment variable manually to one of these addresses: $myips"
else
    echo "Your hostname cannot be resolved in the network, you need to set the ROS_IP environment variable manually to one of these addresses: $myips"
fi
echo "You can use one of the following commands:"
for ip in $myips; do
    echo "  $WS_PREFIX master $1 $ip"
done
