#!/bin/bash

source $ROSWSS_ROOT/setup.bash ""
source $ROSWSS_BASE_SCRIPTS/helper/helper.sh
source $ROSWSS_BASE_SCRIPTS/helper/rosinstall.sh

_NO_SUDO=0
packages=()
for arg in $@; do
    # Exclude arguments passed with -*, e.g., --no-sudo
    if [[ $arg != "-"* && ! -z "$arg" ]]; then
        packages+=("$arg")
    elif [[ $arg == "--no-sudo" ]]; then
        _NO_SUDO=1
    fi
done

hostname=$(hostname)

# update package only if given
if [[ ! -z "${packages[@]}" ]]; then
    echo_info "Pulling packages manually..."
    echo
    for package in "${packages[@]}"; do
        echo_note ">>> $package"

        # try dispatching path using rospack        
        path=$(rospack find -q ${package})
        if [ $path ]; then
            git -C $path pull
            echo
            continue
        fi

        # otherwise dispatching path using wstool
        cd $ROSWSS_ROOT
        path=$(wstool info --only=localname | grep ${package})
        if [ $path ]; then
            wstool update $path
            echo
            continue
        fi

        echo_error "Cannot dispatch path for package '${package}'"
        echo
    done
    echo_info "Done!"
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
        # Only pull if directory exists and is writable
        if [ -d $dir ] && [ -w $dir ]; then
            echo_info ">>> Pulling scripts folder in $dir"
            cd $dir
            git pull
        fi
        echo
    done

    # updating root rosinstalls
    echo_info ">>> Pulling install folder in $ROSWSS_ROOT"
    cd $ROSWSS_ROOT
    git pull
    echo

    # update optional rosinstalls
    if [ -d $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/.git ]; then
        echo_info ">>> Pulling optional installs in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional"
        cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional
        git pull
        echo
    fi

    cd $ROSWSS_ROOT/src

    # merge default rosinstall files from *.rosinstall
    cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR
    count=`ls -1 *.rosinstall 2>/dev/null | wc -l`
    if [ $count != 0 ]; then
        echo_info ">>> Checking default rosinstall updates"
        for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/*.rosinstall; do
            filename=$(basename ${file%.*})
            echo_note "Merging to workspace: ${filename}.rosinstall"
            wstool merge -y $file
            echoc $BLUE "Done (${filename}.rosinstall)"
            echo
        done
    fi

    # running default bash scripts from *.sh
    cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR
    count=`ls -1 *.sh 2>/dev/null | wc -l`
    if [ $count != 0 ]; then
        echo_info ">>> Running default bash scripts"
        for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/*.sh; do
            filename=$(basename ${file%.*})
            echo_note "Running bash script: ${filename}.sh"
            source $file "update"
            echoc $BLUE "Done (${filename}.sh)"
            echo
        done
    fi

    # merge host-specific rosinstall files
    if [ -d $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname ]; then
        cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname
        count=`ls -1 *.rosinstall 2>/dev/null | wc -l`
        if [ $count != 0 ]; then
            echo_info ">>> Checking host-specific rosinstall updates"
            for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname/*.rosinstall; do
                filename=$(basename ${file%.*})
                echo_note "Merging to workspace: ${filename}.rosinstall"
                wstool merge -y $file
                echoc $BLUE "Done (${filename}.rosinstall)"
                echo
            done
        fi
    fi

    # running host-specific bash scripts
    if [ -d $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname ]; then
        cd $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname
        count=`ls -1 *.sh 2>/dev/null | wc -l`
        if [ $count != 0 ]; then
            echo_info ">>> Running host-specific bash scripts"
            for file in $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/$hostname/*.sh; do
                filename=$(basename ${file%.*})
                echo_note "Running bash script: ${filename}.sh"
                source $file "update"
                echoc $BLUE "Done (${filename}.sh)"
                echo
            done
        fi
    fi

    # merged installed optional rosinstall or bash files
    if [ -f "$ROSWSS_ROOT/.install" ]; then
      while read filename; do
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.rosinstall" ]; then
            echo_note "Merging to workspace: ${filename}.rosinstall"
            wstool merge -y $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/$filename.rosinstall
            echoc $BLUE "Done (${filename}.rosinstall)"
            echo
        fi
        if [ -r "$ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.sh" ]; then
            echo_note "Running bash script: ${filename}.sh"
            source $ROSWSS_ROOT/$ROSWSS_INSTALL_DIR/optional/${filename}.sh "update"
            echoc $BLUE "Done (${filename}.sh)"
            echo
        fi
      done <$ROSWSS_ROOT/.install
    fi

    # Call additional update scripts
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
        scripts_pkg=${dir%/scripts}
        scripts_pkg=${scripts_pkg##*/}

        if [ -r "$dir/hooks/update.sh" ]; then
            echo_note "Running bash script: update.sh [$scripts_pkg]"
            . "$dir/hooks/update.sh" $@
            echoc $BLUE "Done (update.sh [$scripts_pkg])"
            echo
        fi

        if [ -d $dir/hooks/update/ ]; then
            for i in `find -L $dir/hooks/update/ -maxdepth 1 -type f -name "*.sh"`; do
                file=${i#$dir/hooks/update/}
                echo_note "Running bash script: ${file} [$scripts_pkg]"
                . "$dir/hooks/update/$file" $@
                echoc $BLUE "Done (${file} [$scripts_pkg])"
                echo
            done
        fi
    done

    echo_info ">>> Updating catkin workspace"
    cd $ROSWSS_ROOT/src
    wstool update -j$(nproc)
    echo

    echo_info ">>> Updating rosdeps for all packages in workspace"
    rosdep update
    if [[ $_NO_SUDO == 1 ]]; then
        rosdep check --ignore-src -y -r --from-paths .
    else
        rosdep install --ignore-src -y -r --from-paths .
    fi
    echo
fi
