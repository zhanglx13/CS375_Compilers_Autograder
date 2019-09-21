#! /bin/bash

cd p1_gradingDir

for entry in ./*
do
    # skip if folder
    if [ ! -d "$entry" ]; then
        # get the username, which is the substring before '_'
        username=$( echo $entry | cut -d'_' -f1)
        # check if the username exists
        if [ ! -d "$username" ]; then
            mkdir $username
        fi
        mv $entry $username
    fi
done
