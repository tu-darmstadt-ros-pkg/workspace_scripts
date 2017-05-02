#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/make_externals.sh" ]; then
        . $dir/make_externals.sh
    fi
done

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
  cd $ROSWSS_ROOT
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

. $ROSWSS_ROOT/setup.bash
