#!/bin/bash

source $ROSWSS_ROOT/setup.bash ""
source $ROSWSS_BASE_SCRIPTS/helper/helper.sh
source $ROSWSS_BASE_SCRIPTS/helper/rosinstall.sh

package=$1

# update package only if given
if [[ ! -z "$package" ]]; then
    roscd $package
    git pull
# otherwise perform full update
else
    # update systems settings
    if [ -d /.git ]; then
        echo_info ">>> Pulling system settings"
        cd /
        sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK git pull
        if [ -d ~/.git-credential-cache/ ]; then
          sudo chown -R $USER:$USER ~/.git-credential-cache/
        fi
        echo
    fi

    # pull base scripts first
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        echo_info ">>> Pulling scripts folder in $dir"
        if [ -d $dir ]; then
            cd $dir
            git pull
        fi
    done

    # updating root rosinstalls
    echo_info ">>> Pulling install folder in $ROSWSS_ROOT"
    cd $ROSWSS_ROOT
    git pull
    echo

    cd $ROSWSS_ROOT/src

    # merge rosinstall files from *.rosinstall
    echo_info ">>> Checking rosinstall updates"
    for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo_note "Merging to workspace: ${filename}.rosinstall"
        wstool merge -y $file
    done

    # merge installed optional rosinstall files from optional/*.rosinstall
    if [ -f "$ROSWSS_ROOT/.install" ]; then
        while read filename; do
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.rosinstall" ]; then
            echo_note "Merging to workspace: ${filename}.rosinstall"
            wstool merge -y $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/$filename.rosinstall
        fi
        done <$ROSWSS_ROOT/.install
    fi
    echo

    # running bash scripts from *.sh
    cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR
    echo_info ">>> Running bash scripts"
    for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/*.sh; do
        filename=$(basename ${file%.*})
        echo_note "Running bash script: ${filename}.sh"
        source $file
        echo
    done

    # running bash scripts from optional/*.sh
    cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional
    if [ -f "$ROSWSS_ROOT/.install" ]; then
        while read filename; do
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.sh" ]; then
            echo_note "Running bash script: ${filename}.sh"
            source $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.sh "install"
        fi
        done <$ROSWSS_ROOT/.install
    fi
    echo

    echo_info ">>> Updating catkin workspace"
    cd $ROSWSS_ROOT/src
    wstool update -j$(nproc)
fi
