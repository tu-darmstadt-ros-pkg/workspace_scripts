#!/bin/sh

# define some colors to use with echo -e
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LGRAY='\033[0;37m'
DGRAY='\033[1;30m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LBLUE='\033[1;34m'
LPURPLE='\033[1;35m'
LCYAN='\033[1;36m'
WHITE='\033[1;37m'
NOCOLOR='\033[0m'

echoc() {
    if [ $# -lt 2 ]; then
      echo "echoc usage: echoc <COLOR> <TEXT>"
      return
    fi

    local color
    color=${1}
    shift
    echo -e "${color}${@}${NOCOLOR}"
}

echo_error() {
    echoc $RED "$@"
}

echo_warn() {
    echoc $YELLOW "$@"
}

echo_debug() {
    echoc $GREEN "$@"
}

echo_info() {
    echoc $LGREEN "$@"
}

echo_note() {
    echoc $LBLUE "$@"
}

aptinstall() {
    for pkg in "$@"; do
        dpkg -s $pkg &>/dev/null || sudo apt -y install $pkg
    done
}

apt_install() {
    aptinstall "$@"
}

aptremove() {
    for pkg in "$@"; do
        if dpkg -s $pkg >/dev/null 2>&1; then
          sudo apt remove $pkg
        fi
    done
}

apt_remove() {
    aptremove "$@"
}

apt_key() {
    key=$1
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key $key || sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key $key
}

apt_add_repository() {
    ppa=$1
    key=$2
    if ! grep -q "^$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        if [ ! -z "$key" ]; then
            echo_info "Adding PPA '$ppa' using key from '$key' ..."
            wget -qO- $key | sudo apt-key add -
        else
            echo_info "Adding PPA '$ppa' ..."
        fi
        sudo apt-add-repository --yes --update "$ppa"
    fi
}

apt_remove_repository() {
    ppa=$1
    key=$2
    if grep -q "^$ppa" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        if [ ! -z "$key" ]; then
            echo_info "Removing PPA '$ppa' and key from '$key' ..."
            echo_warn "Removing GPG keys is not implemented yet!"
            #sudo apt-key del
        else
            echo_info "Removing PPA '$ppa' ..."
        fi
        sudo add-apt-repository --remove --update ppa:$ppa
    fi
}

check_pkg_is_installed() {
    pkg=$1
    dpkg-query -W -f='${Status}' $pkg 2>/dev/null | grep "ok installed"
}

depends() {
    if [ ! -f $ROSWSS_ROOT/.install ]; then
        touch $ROSWSS_ROOT/.install
    fi
      
    for install in "$@"; do
        if ! grep -Fxq "$install" $ROSWSS_ROOT/.install; then
            roswss install $install
        fi
    done
}

wstool_rm() {
    for path in "$@"; do
        if wstool info | grep "$path"; then
            wstool rm $path
        fi
    done
}

append_to_file() {
    local file
    file=$1
    local line
    line=$2

    # check if file exists and create it
    if [ ! -f $file ]; then
        touch $file
    fi

    echo "$line" >> $file
}

append_to_file_if_not_exist() {
    local file
    file=$1
    local line
    line=$2

    # check if file exists and create it
    if [ ! -f $file ]; then
        touch $file
    fi

    # check if entry exists and add it
    if ! grep -Fxq "$line" $file; then
        echo "$line" >> $file
    fi
}

check_if_in_file() {
    local file
    file=$1
    local line
    line=$2

    # check if file exists
    if [ ! -f $file ]; then
        echo 1
        return
    fi

    # check if entry exists
    if ! grep -Fxq "$line" $file; then
        echo 1
        return
    fi

    echo 0
}

remove_from_file() {
    local file
    file=$1
    local line
    line=$2

    sed -i "\?${line}?d" $file
}

remove_from_file_exact() {
    local file
    file=$1
    local line
    line=$2

    sed -i "\?\<${line}\>?d" $file
}

move_scm_location() {
    local scm
    scm=$1;
    local old_path
    old_path=$2
    local new_path
    new_path=$3

    cd ${ROSWSS_ROOT}

    if [ -d ${old_path} ]; then
        echo_note "Old directory location detected, moving ${scm} folder."
        mv ${old_path} ${new_path}
        wstool_rm ${old_path}
    fi
}
