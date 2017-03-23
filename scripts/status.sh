#!/bin/bash

. $ROSWS_ROOT/setup.bash ""

function blueEcho()
{
  echo -ne '\e[0;34m'
  echo $1
  echo -ne '\e[0m'
}

function getSpecBranch()
{
  entry=$1

  desiredBranch=$(wstool info $entry | grep "Spec-Version")
  desiredBranch="${desiredBranch[@]}"
  desiredBranch=${desiredBranch#*: }
  echo $desiredBranch
}

function displayStatus()
{
  old_d=`pwd`
  dir=$1
  desiredBranch=$2

  cd $dir
  if [ -z "$desiredBranch" ]
  then
    desiredBranch=$(git log --pretty='%d' -1 HEAD | perl -ne 'm#(?<=origin/)([^,]*)# && print "$1\n"')
  fi

  if [ -e "$dir/.git" ]
  then
    if [ "$(git rev-parse --abbrev-ref HEAD)" != "$desiredBranch" ] \
       || [ -n "$(git status --porcelain)" ] \
       || [ -n "$(git status | grep -P 'branch is (ahead|behind)')" ]
    then
      echo "$PWD :"
      if [ "$(git rev-parse --abbrev-ref HEAD)" != "$desiredBranch" ]
      then
        git status | grep "On branch" | perl -pe "chomp"
        echo -e " (should be on branch $desiredBranch)"
      fi
      git status | grep -P 'branch is (ahead|behind)'
      git status | grep "modified"
      git status | grep "new file"
      git status | grep "deleted"
      if [ -n "$(git status | grep 'Untracked files')" ]
      then
        git status --porcelain | grep '??' | sed -r 's/^.{3}//' \
        | xargs -I file echo -e '\tuntracked:  '"file"
      fi
      echo
    fi
  elif [ -e "$dir/.hg" ]; then
    if [ "$(hg branch)" != "$desiredBranch" ] \
       || [ -n "$(hg status)" ]
    then
      echo "$PWD :"
      echo "On hg branch `hg branch`"
      hg status
      hg incoming | grep "changes"
      echo
    fi
  #else
    #echo "$PWD is not a repository!"
    #echo
  fi
  cd $old_d
}

cd ${ROSWS_ROOT}
blueEcho "Looking for changes in $PWD ..."
displayStatus $PWD

if [ -d $ROSWS_ROOT/rosinstall/optional/custom/.git ]; then
    cd $ROSWS_ROOT/rosinstall/optional/custom
    blueEcho "Looking for changes in $PWD ..."
    displayStatus $PWD
fi

if [ -d $ROSWS_SCRIPTS/custom/.git ]; then
    cd $ROSWS_SCRIPTS/custom
    blueEcho "Looking for changes in $PWD ..."
    displayStatus $PWD
fi

blueEcho "Looking for changes in ${ROS_WORKSPACE} ..."
roscd
entries=$(wstool foreach echo)
for e in ${entries[@]};
do
  e=${e#*[}
  e=${e%]*}
  branch=$(getSpecBranch $e)
  displayStatus $ROSWS_ROOT/$e $branch
done

blueEcho "Status check done!"

