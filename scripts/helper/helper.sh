#!/bin/sh

append_to_file()
{
    file=$1
    line=$2

    # check if file exists and create it
    if [ ! -f $file ]; then
         touch $file
    fi

    echo "$line" >> $file
}

append_to_file_if_not_exist()
{
    file=$1
    line=$2

    # check if file exists and create it
    if [ ! -f $file ]; then
         touch $file
    fi

    # check if entry exists and add it
    if ! grep -Fxq "$line" $file; then
      echo "$line" >> $file
    fi
}

remove_from_file()
{
    file=$1
    line=$2

    sed -i "\?${line}?d" $file
}

remove_from_file_exact()
{
    file=$1
    line=$2

    sed -i "\?\<${line}\>?d" $file
}
