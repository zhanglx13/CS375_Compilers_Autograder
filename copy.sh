#! /usr/bin/env bash

AUTOGRADERDIR=$(pwd)
FILEDIR=$AUTOGRADERDIR/cs375_minimal
LOCAL_DIR=~/CS375_gradingDir
if [ ! -d $LOCAL_DIR ];
then
    mkdir $LOCAL_DIR
fi

##
## Algorithm:
##
##   1. Cd into the submission dir. Each file in the dir has the following form:
##      lastnamefirstname_LATE_13344546q3545_parse-2.y
##   2. Check if there is a dir named as lastnamefirstname in $LOCAL_DIR
##      2.1 If not there, we need to create the folder and copy student's
##          code as well as other important code into the folder
##      2.2 If the folder exists, we only need to copy student's code into
##          the folder
##
cd ~/submissions_$1
for submittedFile in ./*
do
    # get the student's name, which is the substring before '_'
    sname=$( echo $submittedFile | cut -d'_' -f1)
    echo "processing student: $sname"
    if [ ! -d "$LOCAL_DIR/$sname" ];
    then
        ##
        ## The student's folder does not exists
        ##
        ## Create the folder
        mkdir $LOCAL_DIR/$sname
        ## Copy all utility files into the folder
        cp $FILEDIR/* $LOCAL_DIR/$sname
    fi
    ##
    ## Now the student's folder is guaranteed to exist
    ## Next we need to copy student's submitted files
    ## into the folder
    ##
    ## the downloaded submitted file has the following form
    ## 
    ## name_LATE_3454987397_397484737_parse-3.y
    ##
    ## The goal is to extract the basename of the file without
    ## version number
    ##
    ## Step 1: extract the filename with version number
    fwithV=$(echo ${submittedFile##*_})
    ## Step 2: replace version number (-[1-9]) with nothing
    ##         Need to do it twice because version number
    ##         can have two digits
    fwithoutV=$(echo ${fwithV/-[0-9]})
    fwithoutV=$(echo ${fwithoutV/[0-9]})
    ## Step 3: copy and rename the file
    cp $submittedFile $LOCAL_DIR/$sname/$fwithoutV
done
