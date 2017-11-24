#!/bin/bash

. $ROSWSS_ROOT/setup.bash

package=$1

# update package only if given
if [[ ! -z "$package" ]]; then
    roscd $package
    git pull
# otherwise perform full update
else
    # update systems settings
    if [ -d /.git ]; then
        echo ">>> Pulling system settings"
        cd /
        sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK git pull
        if [ -d ~/.git-credential-cache/ ]; then
          sudo chown -R $USER:$USER ~/.git-credential-cache/
        fi
        echo
    fi

    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        echo ">>> Pulling scripts folder in $dir"
        cd $dir
        git pull
    done

    # Remove obsolete stuff using wstool
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        if [ -f "$dir/helper/rm_obsolete_packages.sh" ]; then
            $dir/helper/rm_obsolete_packages.sh
        fi
    done

    echo ">>> Pulling install folder in $ROSWSS_ROOT"
    cd $ROSWSS_ROOT
    git pull
    echo

    if [ -d $ROSWSS_ROOT/rosinstall/optional/custom/.git ]; then
        echo ">>> Pulling custom rosinstalls"
        cd $ROSWSS_ROOT/rosinstall/optional/custom
        git pull
        echo
    fi

    echo ">>> Checking package updates"
    ./rosinstall/install_scripts/install_package_dependencies.sh
    echo

    echo ">>> Checking rosinstall updates"
    # merge rosinstall files from rosinstall/*.rosinstall
    for file in $ROSWSS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: '$filename'.rosinstall"
        wstool merge $file -y
    done

    # merge installed optional rosinstall files from rosinstall/optional/*.rosinstall
    while read filename; do
      echo "Merging to workspace: '$filename'.rosinstall"
      wstool merge $ROSWSS_ROOT/rosinstall/optional/$filename.rosinstall -y
    done <$ROSWSS_ROOT/.install
    echo

    echo ">>> Updating catkin workspace"
    cd $ROSWSS_ROOT/src
    wstool update -j$(nproc)

    echo ">>> Installing package dependencies"
    $ROSWSS_ROOT/rosinstall/install_scripts/install_package_dependencies.sh
fi
