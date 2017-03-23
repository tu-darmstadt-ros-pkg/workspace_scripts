#!/bin/bash

. $ROSWS_ROOT/setup.bash

package=$1

# update package only if given
if [[ ! -z "$package" ]]; then
    roscd $package
    git pull
# otherwise perform full update
else
    sudo echo

    echo ">>> Pulling scripts folder in $ROSWS_SCRIPTS"
    cd $ROSWS_SCRIPTS
    git pull

    # Remove obsolete stuff using wstool
    $ROSWS_SCRIPTS/helper/rm_obsolete_packages.sh

    echo ">>> Pulling install folder in $ROSWS_ROOT"
    cd $ROSWS_ROOT
    git pull
    echo

    echo ">>> Checking package updates"
    ./rosinstall/install_scripts/install_package_dependencies.sh
    echo

    # merge rosinstall files from rosinstall/*.rosinstall
    for file in $ROSWS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: '$filename'.rosinstall"
        wstool merge $file -y
    done
    echo

    if [ -d $ROSWS_ROOT/rosinstall/optional/custom/.git ]; then
        echo ">>> Pulling custom rosinstalls"
        cd $ROSWS_ROOT/rosinstall/optional/custom
        git pull
        echo
    fi

    if [ -d $ROSWS_SCRIPTS/custom/.git ]; then
        echo ">>> Pulling custom scripts"
        cd $ROSWS_SCRIPTS/custom
        git pull
        echo
    fi

    cd $ROSWS_ROOT
    echo ">>> Merging rosinstall files"
    for file in $ROSWS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: $filename.rosinstall"
        wstool merge $file -y
    done
    echo

    echo ">>> Updating catkin workspace"
    cd $ROSWS_ROOT/src
    wstool update

    echo ">>> Installing package dependencies"
    $ROSWS_ROOT/rosinstall/install_scripts/install_package_dependencies.sh
fi
