#!/bin/bash

source $ROSWSS_BASE_SCRIPTS/helper/helper.sh

if [ "$#" -lt 1 ]; then
    echo "Usage: wget full_url (filename)"
    exit 1
fi

url=$1
filename=$2
domain=$(awk -F/ '{print $3}' <<< "$url")

# dispatch domain and download method
case $domain in
    drive.google.com)
        echo_info "Downloading from Google Drive..."
        apt_install python-pip
        pip install gdown --quiet
        
        args=$([ -z ${filename} ] || echo "-O ${filename}")
        gdown --fuzzy ${url} ${args}
        ;;
    *)
        echo_info "Downloading using wget..."
        apt_install wget
        
        args=$([ -z ${filename} ] || echo "-O ${filename}")
        wget ${url} ${args}
        ;;
esac

