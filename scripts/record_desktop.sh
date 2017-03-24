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

usage="Usage: rd  [OPTION]... VALUE...
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
record_audio=""
loop_audio=false
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
        record_audio="-f alsa -ac 2 -i pulse -acodec pcm_s16le"
        ;;
    l)
        record_audio="-f alsa -ac 2 -i pulse -acodec pcm_s16le"
        loop_audio=true
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
        echo 'rd  1.0'
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

now="$(date +'%d-%m-%Y_%H:%M:%S')"
lightgreen='\033[1;32m'
NC='\033[0m' # No Color

if [ "$use_display" = true ]; then
    if echo "$display" | grep -qE ^\-?[0-9]?\.?[0-9]+$ ; then
        string=$(xrandr | grep \* | awk '{print $1'})
        #echo "$string"
        arr=()
        count=0
        x_acum=0
        while read -r line; do
            arr+=("$line")
            count=$[$count +1]
        done <<< "$string"
        echo "Found $count displays"
        if [ "$display" -ge 0 ] && [ "$display" -lt "$count" ]; then
            i="0"
            while [ $i -lt $display ]; do
                x_acum=$[$x_acum + $(echo ${arr["$i"]} | cut -f1 -dx)]
                i=$[$i+1]
            done
            resolution=${arr["$display"]}
            x_off=$x_acum
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

   if [ "$loop_audio" = true ]; then 
       module=`pactl load-module module-loopback` #Loads the audio module to loopback and stores it or later unload
   fi
   if   [  -n "$record_audio" ]; then
        pavucontrol &
   fi

   if [ "$file_path" = "" ]; then
     echo "use time stamped name ..."
     full_path=screencast_$now.mkv
   else
     echo "use path and hostname ..."
     full_path=$file_path"/"$HOSTNAME"_desktop.mkv"
   fi 

   echo "Recording at $resolution with $x_off,$y_off offset"
   echo " to $full_path"
   ffmpeg  $record_audio -s $resolution -f x11grab -i :0.0+$x_off,$y_off -vcodec libx264 -preset ultrafast -crf 0 -threads 0 $full_path
   echo -e "${lightgreen}Recorded to screencast_$now.mkv${NC}"

   if [ "$loop_audio" = true ]; then
       pactl unload-module $module     #Unloads the audio loopback
   fi
   if  [ -n "$record_audio" ]; then
       pidofpavu=$(pidof pavucontrol)
       if  [ -n "$pidofpavu" ]; then
            kill -9 $pidofpavu
       fi
   fi

fi



