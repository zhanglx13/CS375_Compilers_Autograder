#! /bin/bash

##
## $1 folder that contains all students submissions
## $2 source file name to be checked
##
## E.g.
## ./check_moss.sh p5_gradingDir parse.y
##
TOP_DIR=$(pwd)

if [[ $# -eq 2 ]]; then

    mkdir -p moss_checkDir
    
    for studentDir in $1/*
    do
        echo $studentDir
        studentname=${studentDir##*/}
        echo $studentname
        newfilename=$studentname"_"$2
        echo $newfilename
        cp $studentDir/$2 moss_checkDir/
        mv moss_checkDir/$2 moss_checkDir/$newfilename
    done
    cp moss.sh moss_checkDir/
    cd moss_checkDir
    ./moss.sh *.y
else
    echo "Usage: ./check_moss.sh dir filename"
fi
