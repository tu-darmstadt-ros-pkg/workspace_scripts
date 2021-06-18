#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

master=$1
if [ -z "$master" ]; then
	echo "Usage: $ROSWSS_PREFIX master MASTER_HOSTNAME_OR_IP [LOCAL_HOSTNAME_OR_IP]"
	return
fi

master_ip=$(echo $master | egrep "([0-9]+\.){3}[0-9]+")

# resolve master only if it is not already an IP address
if [ "$master" != "$master_ip" ] && [ "$master" != "localhost" ]; then
	host -t a $master >/dev/null
	if [ "$?" -ne 0 ]; then
	    echo_warn "Host $master cannot be resolved at the moment!"
	fi
fi

# export ROS_MASTER_URI
export ROS_MASTER_URI=http://$master:11311
echo_info "Setting ROS_MASTER_URI to $ROS_MASTER_URI"

# check command line for ROS_IP
local_ip=$2
if [ -z "$local_ip" ]; then
	num_ips=$(hostname -I | egrep -o "([0-9]+\.){3}[0-9]+" | grep -c ".*")
	if [ "$num_ips" == "0" ]; then
    	# if there is no IP in the system, use loopback as ROS_IP
		local_ip=127.0.0.1
	elif [ "$num_ips" == "1" ]; then
    	# if there is only one IP in the system, use it as ROS_IP
		local_ip=$(hostname -I | egrep -o "([0-9]+\.){3}[0-9]+")
	fi
fi
# export ROS_IP
if [ -n "$local_ip" ]; then
    export ROS_IP=$local_ip
    echo_info "Setting ROS_IP to $ROS_IP"
    return
fi

# if ROS_IP is already set to an IP that belongs to this host, exit here
if [ -n "$(hostname -I | grep -o $ROS_IP)" ]; then
    echo_info "ROS_IP is already set to valid IP: $ROS_IP"
	return
fi

# clear invalid ROS_IP value
export ROS_IP=

# give some information about possible ROS_IP settings
echo
hostname=$(hostname)
if [ -n "$ROS_HOSTNAME" ]; then
	hostname=$ROS_HOSTNAME
fi

myips=$(hostname -I)
echo_note "Your hostname is: "
host -t a $hostname
if [ $? -eq 0 ]; then
    echo_info "If this hostname cannot be resolved on the master ($master), you need to set the ROS_IP environment variable."
else
    echo_warn "Your hostname cannot be resolved in the network, you need to set the ROS_IP environment variable."
fi
echo_note "You can use one of the following commands:"
for local_ip in $myips; do
    echo "  $ROSWSS_PREFIX master $1 $local_ip"
done
