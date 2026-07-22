#!/usr/bin/env bash

source ${ROSWSS_BASE_SCRIPTS}/helper/helper.sh

if [ "$#" -eq 0 ]; then
    echo "Usage: ssh host [Command (optional)]"
    exit 1
fi

host=$1; shift

# convert to arrays
hosts=(${ROBOT_HOSTNAMES})
users=(${ROBOT_USERS})

# check if multiple users are defined
if [ -z "${ROBOT_USERS}" ]; then
    # if not, look for single user definition (backwards compatibility)
    if [ -z "${ROBOT_USER}" ]; then
        echo_error "ERROR: In order to use the ssh command, please set ROBOT_USER or ROBOT_USERS." 
        exit 1
    else
        user=${ROBOT_USER}
    fi
else
    # else look for the array index of the host name
    for idx in "${!hosts[@]}"; do 
        if [ "${hosts[$idx]}" = "${host}" ]; then
            # take corresponding user
            user="${users[$idx]}"
            break
        fi
    done
fi

# check if we found a valid user
if [ -z "${user}" ]; then
    echo_error "Unknown host '${host}'"
    exit
fi

if command -v opkssh &>/dev/null; then
  if [[ -f "$HOME/.ssh/id_ecdsa-cert.pub" ]]; then
    OPKSSH_CERT="$HOME/.ssh/id_ecdsa-cert.pub"
  else
    OPKSSH_CERT="$HOME/.ssh/id_ecdsa.pub"
  fi
  if [[ -f "$OPKSSH_CERT" ]]; then
    CERT_AGE=$(( $(date +%s) - $(stat -c %Y "$OPKSSH_CERT") ))
    if (( CERT_AGE >= 86400 )); then
      echo "opkssh cert expired, re-authenticating..."
      opkssh login keycloak
    fi
  else
    echo "opkssh cert not found, authenticating..."
    opkssh login keycloak
  fi
else
  echo "opkssh cert not found, authenticating..."
  opkssh login keycloak
fi

# connect via SSH
echo_info "Connecting to machine \"${host}\" as user \"${user}\"..."
if [ "$#" -eq 0 ]; then
    ssh ${user}@${host} -A
else
    ssh ${user}@${host} -A -t "bash -l -c -i '$@'"
fi
