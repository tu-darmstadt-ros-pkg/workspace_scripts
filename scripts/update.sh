#!/bin/bash

. $WS_ROOT/setup.bash

package=$1

# update package only if given
if [[ ! -z "$package" ]]; then
    roscd $package
    git pull
# otherwise perform full update
else
    sudo echo

    echo ">>> Pulling scripts folder in $WS_SCRIPTS"
    cd $WS_SCRIPTS
    git pull

    # Remove obsolete stuff using wstool
    $WS_SCRIPTS/helper/rm_obsolete_packages.sh

    echo ">>> Pulling install folder in $WS_ROOT"
    cd $WS_ROOT
    git pull
    echo

    echo ">>> Checking package updates"
    ./rosinstall/install_scripts/install_package_dependencies.sh
    echo

    # merge rosinstall files from rosinstall/*.rosinstall
    for file in $WS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: '$filename'.rosinstall"
        wstool merge $file -y
    done
    echo

    if [ -d $WS_ROOT/rosinstall/optional/custom/.git ]; then
        echo ">>> Pulling custom rosinstalls"
        cd $WS_ROOT/rosinstall/optional/custom
        git pull
        echo
    fi

    if [ -d $WS_SCRIPTS/custom/.git ]; then
        echo ">>> Pulling custom scripts"
        cd $WS_SCRIPTS/custom
        git pull
        echo
    fi

    cd $WS_ROOT
    echo ">>> Merging rosinstall files"
    for file in $WS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: $filename.rosinstall"
        wstool merge $file -y
    done
    echo

    echo ">>> Updating catkin workspace"
    cd $WS_ROOT/src
    wstool update

    echo ">>> Installing package dependencies"
    $WS_ROOT/rosinstall/install_scripts/install_package_dependencies.sh
fi
