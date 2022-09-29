#! /bin/bash
# Copyright (C) 2015 Team ViGIR.

# The GNU C Library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# The GNU C Library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with the GNU C Library; if not, see
# <http://www.gnu.org/licenses/>.


# This is the `record_desktop' command, which records your desktop.
# If no argument is received full resolution is used. 

usage="Usage: record_desktop  [OPTION]... VALUE...
        -h,            print this help and exit
        -v,            print version information and exit
        -d,            records display number: [0- Number of displays available] (e.g. -d 0) 
        -r,            records a given resolution (e.g. -r 1980x1080)
        -o,            sets an offset for recorded region (e.g. -o 50X50)
        -a,            records audio from microphone
        -l,            records audio from speakers
        -p,            specify a path for the files
For bug reports, please contact: romay@sim.tu-darmstadt.de"

resolution=$(xdpyinfo | grep dimensions | awk '{print $2'})   #Default resolution for al desktops on all screens
offset=0x0
record=true
use_display=false
record_speakers_audio=""
record_microphone_audio=""
record_audio=""
map_mic=false
map_speakers=false
mix_mic_speakers=""
file_path=""
module=

while getopts ":hvr:d:o:alp:" opt; do
  case $opt in
    r)
        resolution=$OPTARG
        ;;
    d)
        display=$OPTARG
        use_display=true
        ;;
    o)
        offset=$OPTARG
        ;;
    a)
        echo "Looking for microphones"
        MICROPHONES="$(pacmd list-sources | grep "\.analog-" | grep -v "monitor" | grep -o -P '(?<=<).*(?=>)')"
        MICS=($MICROPHONES) # Convert string into array


        if [ "${#MICS[@]}" = 1 ]; then
            echo "Found only one Microphone, using it."
            MIC_ID=0
        else
            echo "Found ${#MICS[@]} microphones: "
            until [[ $MIC_ID =~ ^[0-$((${#MICS[@]}-1))]+$ ]]; do
                for index in "${!MICS[@]}"
                do
                    echo "$index ${MICS[index]}"
                done
                echo -n "Which Microphone index do you want to record from [${!MICS[@]}] ?: "
                read -r -e MIC_ID
            done
        fi

        echo  "Recording Microphone Selected: ${MICS[$MIC_ID]}"  
	    record_microphone_audio="-f pulse -ac 2 -ar 48000 -i ${MICS[$MIC_ID]}"
	    record_audio="-acodec pcm_s16le"
	    map_mic=true
        ;;
    l)
        echo "Looking for speakers"
        SPEAKERS="$(pacmd list-sources | grep "\.monitor" | grep -o -P '(?<=<).*(?=>)')"
        SPEAK=($SPEAKERS) # Convert string into array


        if [ "${#SPEAK[@]}" = 1 ]; then
            echo "Found only one Speaker, using it."
            SPEAK_ID=0
        else
            echo "Found ${#SPEAK[@]} speakers: "
            until [[ $SPEAK_ID =~ ^[0-$((${#SPEAK[@]}-1))]+$ ]]; do
                for index in "${!SPEAK[@]}"
                do
                    echo "$index ${SPEAK[index]}"
                done
                echo -n "Which Speaker index do you want to record from [${!SPEAK[@]}] ?: "
                read -r -e SPEAK_ID
            done
        fi

        echo  "Recording Speakers Selected: ${SPEAK[$SPEAK_ID]}"
	    record_speakers_audio="-f pulse -ac 2 -ar 44100 -i ${SPEAK[$SPEAK_ID]}"
	    record_audio="-acodec pcm_s16le"
	    map_speakers=true
        ;;
    h)
        echo "$usage"
        exit 1
        ;;
    p)
        file_path=$OPTARG
        echo "Using file_path=$file_path"
        ;;
    \?)
        echo "Invalid option: -$OPTARG" >&2
        echo "$usage"
        exit 1
        ;;

    v)  
        echo 'record_desktop  1.1'
        printf $"Copyright (C) %s Team ViGIR.
        This is free software; see the source for copying conditions.  There is NO
        warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
        " "2015"
        printf $"Written by %s.
        " "Alberto Romay"
        exit 1
        ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      echo "$usage"
      exit 1
      ;;
  esac
done

x_off=$(echo $offset | cut -f1 -dx)
y_off=$(echo $offset | cut -f2 -dx)

now="$(date +'%d-%m-%Y_%H-%M-%S')"
lightgreen='\033[1;32m'
NC='\033[0m' # No Color

if [ "$use_display" = true ]; then
    if echo "$display" | grep -qE ^\-?[0-9]?\.?[0-9]+$ ; then
        arr_res=()
        arr_x_off=()
        arr_y_off=()
        count=0
        x_acum=0

        string=$(xrandr | grep -o "[0-9]*x[0-9]*+[0-9]*+[0-9]*" | grep -o "[0-9]*x[0-9]*")  #Get resolutions
        #echo "$string"
        while read -r line; do
            arr_res+=("$line")
            count=$[$count +1]
        done <<< "$string"

	string=$(xrandr | grep -o "[0-9]*x[0-9]*+[0-9]*+[0-9]*" | grep -o "+[0-9]*+" | grep -o "[0-9]*")  #Get x offsets
        #echo "$string"
        while read -r line; do
            arr_x_off+=("$line")
        done <<< "$string"

	string=$(xrandr | grep -o "[0-9]*x[0-9]*+[0-9]*+[0-9]*" | grep -o "+[0-9]*$" | grep -o "[0-9]*")  #Get y offsets
        #echo "$string"
        while read -r line; do
            arr_y_off+=("$line")
        done <<< "$string"


        echo "Found $count displays"
        if [ "$display" -ge 0 ] && [ "$display" -lt "$count" ]; then
            resolution=${arr_res["$display"]}
            x_off=${arr_x_off["$display"]}
            y_off=${arr_y_off["$display"]}
        else
            count=$[$count -1]
            echo "Display number $display out of range [0-$count]"
            record=false
        fi
    else
        echo "\"$display\" is not a number"
        record=false
    fi
fi


if [ "$record" = true ]; then

   if [ "$file_path" = "" ]; then
     echo "use time stamped name ..."
     full_path=screencast_$now.mkv
   else
     echo "use path and hostname ..."
     full_path=$file_path"/"$HOSTNAME"_desktop.mkv"
   fi 
    
    echo "map_mic: $map_mic"
    echo "map_speakers: $map_speakers"
    if [ "$map_mic" = true ] && [ "$map_speakers" = true ]; then
        echo "MIXING CHANNELS"
        mix_mic_speakers="-filter_complex amix=inputs=2"
    fi

   echo "Recording at $resolution with $x_off,$y_off offset"
   echo " to $full_path"
   ffmpeg  $record_speakers_audio $record_microphone_audio $mix_mic_speakers $record_audio -s $resolution -f x11grab -i :0.0+$x_off,$y_off -vcodec libx264 -preset ultrafast -threads 0 $full_path
   echo -e "${lightgreen}Recorded to screencast_$now.mkv${NC}"

fi
