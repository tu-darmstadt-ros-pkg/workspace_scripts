#!/bin/bash

# executes all scripts and launchfiles in a path given as argument

trap 'shutdown' INT TERM EXIT

shutdown() {
    trap '' INT TERM EXIT   # ignore INT, TERM and EXIT while shutting down
    echo
    echo "**** Shutting down... ****"
    echo

    for screen in "${started_screens_array[@]}"
    do
      echo "killing screen $screen"
      screen -X -S $screen quit
      echo 'killed successfully'
    done

    exit 0
}

read_arguments() {
	# check if arguments were given
	if [ $# -lt 1 ]; then
		echo 'Usage: ./execute <directory list> [-p preexecute_commands]' >&2
		echo 'it is recommended to start this script in a screen' >&2
		exit 1
	fi

	# first argument is the path
	DIRECTORY=$1
	if [ ! -d $DIRECTORY ]; then 
		echo "Directory $DIRECTORY does not exist"
		exit 1
	fi

	# put all directories into an array
	counter=0
	while [ -d $DIRECTORY ]; 
	do
		directories[${counter}]=$DIRECTORY
		(( counter=$counter + 1 ))
		shift
		DIRECTORY=$1
	done

	# read input arguments
	LOG_DIR=$ROSWSS_ROOT/logs
	while getopts 'p:l:' opt ; do
		case "$opt" in
		    p) PREEXECUTE_COMMAND=$OPTARG ;; #source $ROSWSS_ROOT/install/setup.sh
		    l) LOG_DIR=$OPTARG ;;
		    \?) echo "Could not interpret Option $OPTARG" ;;
		    :)  echo "Option -$OPTARG requires input Arguments" ;;
		esac
	done
}

run_scripts() {
	# run all scripts in script folder
	echo ">>>>> Executing scripts: "
	for files in $DIRECTORY/*.sh
	do
	if [ -f $files ]; then
		# getting script name for screen session
		screen_session=${files##*/}
		screen_session=${screen_session%%.sh}_script

		    started_screens_array[${counter}]=$screen_session
		echo "    executing ${started_screens_array[${counter}]}"
		    (( counter=$counter + 1 ))

		# create subfolders for each screen, there seems to be no option to change the output file name
		mkdir -p $LOG_DIR/$screen_session
		cd $LOG_DIR/$screen_session
		[ -f screenlog.0 ] && rm screenlog.0
		screen -dmLS $screen_session /bin/bash -ic "$PREEXECUTE_COMMAND && bash $files"
	fi
	done

	# launch all launchfiles
	echo ">>>>> Launching launchfiles"

	for files in $DIRECTORY/*.launch
	do
	if [ -f $files ]; then
		# getting launchfile name for screen session
		screen_session=${files##*/}
		screen_session=${screen_session%%.launch}_launch

		started_screens_array[${counter}]=$screen_session
		echo "   running ${started_screens_array[${counter}]}"
		    (( counter=$counter + 1 ))

		#echo $screen_session >> /home/$(whoami)/started_screen_sessions.txt
		# create subfolders for each screen, there seems to be no option to change the output file name
		mkdir -p $LOG_DIR/$screen_session
		cd $LOG_DIR/$screen_session
		[ -f screenlog.0 ] && rm screenlog.0
		screen -dmLS $screen_session /bin/bash -ic "$PREEXECUTE_COMMAND && roslaunch $files"
	fi
	done
}

# program start, init variables
PREEXECUTE_COMMAND=""
LOG_DIR=$ROSWSS_ROOT/logs
# array for reading input directories
declare -a directories

# read input arguments
read_arguments "$@"

# run scripts for each directory
for entry in ${directories[@]}
do
    DIRECTORY=$entry
	run_scripts 
done 

echo ">>>>> Done"

# wait forever to be able to shutdown screens later
cat
