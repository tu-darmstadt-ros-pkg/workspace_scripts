#!/bin/bash
set -e

for dir in ${ROSWSS_SCRIPTS//:/ }; do
    if [ -r "$dir/make_externals.sh" ]; then
        . $dir/make_externals.sh
    fi
done

# check if debug compile is set
args=("$@")
debug=false
for (( i=0; i<${#args[@]}; i++ )); do
  var=${args[i]}
  if [ "$var" == "debug" ]; then
    debug=true
    args=( "${args[@]:0:$i}" "${args[@]:$((i + 1))}" )
    break
  fi
done

# check for single pkg compile
change_dir=true
for var in $args; do
  if [ "$var" == "--this" ]; then
    change_dir=false
    break
  fi
done

if [ $change_dir == true ] ; then
  cd $ROSWSS_ROOT

  # clean removed or disabled packages
  catkin clean --orphans
fi

# add proper compile flag
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
