#!/bin/bash

. $ROSWSS_ROOT/setup.bash

package=$1

# update package only if given
if [[ ! -z "$package" ]]; then
    roscd $package
    git pull
# otherwise perform full update
else
    echo ">>> Pulling scripts folder in $ROSWSS_SCRIPTS"
    cd $ROSWSS_SCRIPTS
    git pull

    # Remove obsolete stuff using wstool
    $ROSWSS_SCRIPTS/helper/rm_obsolete_packages.sh

    echo ">>> Pulling install folder in $ROSWSS_ROOT"
    cd $ROSWSS_ROOT
    git pull
    echo

    echo ">>> Checking package updates"
    ./rosinstall/install_scripts/install_package_dependencies.sh
    echo

    # merge rosinstall files from rosinstall/*.rosinstall
    for file in $ROSWSS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: '$filename'.rosinstall"
        wstool merge $file -y
    done
    echo

    if [ -d $ROSWSS_ROOT/rosinstall/optional/custom/.git ]; then
        echo ">>> Pulling custom rosinstalls"
        cd $ROSWSS_ROOT/rosinstall/optional/custom
        git pull
        echo
    fi

    if [ -d $ROSWSS_SCRIPTS/custom/.git ]; then
        echo ">>> Pulling custom scripts"
        cd $ROSWSS_SCRIPTS/custom
        git pull
        echo
    fi

    cd $ROSWSS_ROOT
    echo ">>> Merging rosinstall files"
    for file in $ROSWSS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: $filename.rosinstall"
        wstool merge $file -y
    done
    echo

    echo ">>> Updating catkin workspace"
    cd $ROSWSS_ROOT/src
    wstool update

    echo ">>> Installing package dependencies"
    $ROSWSS_ROOT/rosinstall/install_scripts/install_package_dependencies.sh
fi
