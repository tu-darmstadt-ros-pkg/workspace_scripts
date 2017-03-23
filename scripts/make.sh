#!/bin/bash
set -e

. $ROSWS_SCRIPTS/make_externals.sh

# check if debug compile is set
debug=false
if [ "$1" == "debug" ]; then
  shift
  debug=true
fi

# check for single pkg compile
change_dir=true
for var in "$@"
do
  if [ "$var" == "--this" ]; then
    change_dir=false
    break
  fi
done

if [ $change_dir == true ] ; then
  cd $ROSWS_ROOT
fi

# add proper compile flag
args="$@"
if [ $debug == true ]; then
  echo
  echo "-------------------- Debug build --------------------"
  args="-DCMAKE_BUILD_TYPE=Debug $args"
else
  echo
  echo "------------------- Default build -------------------"
fi
echo ">>> Building with arguments '$args'"
echo "-----------------------------------------------------"
echo

catkin build $args

. $ROSWS_ROOT/setup.bash
