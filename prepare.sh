#! /bin/bash

if [[ $# -eq 0 ]]; then
    echo "Please select a project px"
else
    echo "Preparing for project $1"
    dtrx "submissions_$1.zip"
    mv "submissions_$1" "$1_gradingDir"
    ./mkdir.sh $1
    ./copy.sh $1
fi
