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

    # pull base scripts first
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        echo ">>> Pulling scripts folder in $dir"
        if [ -d $dir ]; then
            cd $dir
            git pull
        fi
    done

    # updating root rosinstalls
    echo ">>> Pulling install folder in $ROSWSS_ROOT"
    cd $ROSWSS_ROOT
    git pull
    echo

    # updating custom rosinstalls
    if [ -d $ROSWSS_ROOT/rosinstall/optional/custom/.git ]; then
        echo ">>> Pulling custom rosinstalls"
        cd $ROSWSS_ROOT/rosinstall/optional/custom
        git pull
        echo
    fi

    cd $ROSWSS_ROOT/src

    # merge rosinstall files from rosinstall/*.rosinstall
    echo ">>> Checking rosinstall updates"
    for file in $ROSWSS_ROOT/rosinstall/*.rosinstall; do
        filename=$(basename ${file%.*})
        echo "Merging to workspace: ${filename}.rosinstall"
        wstool merge $file -y
    done

    # merge installed optional rosinstall files from rosinstall/optional/*.rosinstall
    if [ -f "$ROSWSS_ROOT/.install" ]; then
        while read filename; do
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${filename}.rosinstall" ]; then
            echo "Merging to workspace: ${filename}.rosinstall"
            wstool merge $ROSWSS_ROOT/rosinstall/optional/$filename.rosinstall -y
        fi
        done <$ROSWSS_ROOT/.install
    fi
    echo

    # running bash scripts from rosinstall/*.sh
    echo ">>> Running bash scripts"
    for file in $ROSWSS_ROOT/rosinstall/*.sh; do
        filename=$(basename ${file%.*})
        echo "[Running bash script: ${filename}.sh]"
        $file
        echo
    done

    # running bash scripts from rosinstall/optional/*.sh
    if [ -f "$ROSWSS_ROOT/.install" ]; then
        while read filename; do
        if [ -r "$ROSWSS_ROOT/rosinstall/optional/${filename}.sh" ]; then
            echo "[Running bash script: ${filename}.sh]"
            $ROSWSS_ROOT/rosinstall/optional/${filename}.sh "install"
        fi
        done <$ROSWSS_ROOT/.install
    fi
    echo

    echo ">>> Updating catkin workspace"
    cd $ROSWSS_ROOT/src
    wstool update -j$(nproc)
fi
