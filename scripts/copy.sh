#! /usr/bin/env bash

AUTOGRADERDIR=$(pwd)
FILEDIR=$AUTOGRADERDIR/cs375_minimal
LOCAL_DIR=~/CS375_gradingDir
if [ ! -d $LOCAL_DIR ];
then
    mkdir $LOCAL_DIR
fi

##
## These files will be overwritten by the version in the utility folder
## if students also submit their own version
##
declare -A banArray
banArray=(
    [pprint.c]=1
    [printtoken.c]=1
    [pprint.h]=1
)
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
zipFound=0
for submittedFile in ./*
do
    # get the student's name, which is the substring before '_'
    sname=$( echo $submittedFile | cut -d'_' -f1)
    sname=${sname##*/}
    echo "processing student: $sname"
    if [ ! -d "$LOCAL_DIR/$sname" ];
    then
        ##
        ## The student's folder does not exists
        ##
        ## Create the folder
        mkdir $LOCAL_DIR/$sname
        ## Copy all utility files into the folder
        ##
        ## Note that this is done iff the student dir does not exist
        ## before. Since student might submit multiple files for
        ## any project, their submitted files will be overwritten
        ## if the utility files are copied after student's file is
        ## converted and copied.
        ##
        cp $FILEDIR/* $LOCAL_DIR/$sname
    fi
    ##
    ## Check if the student has submitted a .zip file
    ##
    ext=$(echo ${submittedFile##*.})
    if [[ $ext == "zip" ]] || [[ $ext == "tar" ]]; then
        echo "zip or tar file found: $submittedFile"
        zipFound=1
        fname=$(echo ${submittedFile%.*})
        fname=$(echo ${fname##*/})
        ## Extract the zip package using the rename policy
        dtrx --one=rename $submittedFile
        ## Copy student's files
        ## cp will automatically ignore folders since we do not
        ## specify -r
        ## Only copy the file if it is not in the banarray
        for f in $fname/*
        do
            ff=${f##*/}
            if [[ ${banArray[$ff]} -eq 0 ]]; then
                cp $f $LOCAL_DIR/$sname
            fi
        done
        ## Remove the unzipped dir
        rm -r $fname
    else
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
        ## Step 3: Just in case that the filename now has the form of
        ##
        ##         parse ().y
        ##
        ##        In this case, we need to delete space, (, and )
        fwithoutV=$(echo ${fwithoutV/[\ ]})
        fwithoutV=$(echo ${fwithoutV/()})
        ## Step 4: copy and rename the file if it's not in the banArray
        if [[ ${banArray[$fwithoutV]} -eq 0 ]]; then
            ##
            ## Note that when filename contains space and other wild
            ## chars, putting the filename into "" handles everything.
            ##
            cp "$submittedFile" $LOCAL_DIR/$sname/$fwithoutV
        fi
        ##
        ## Copy autograder utility files into the student dir
        ##
        cp $FILEDIR/pprint.c $LOCAL_DIR/$sname
        cp $FILEDIR/pprint.h $LOCAL_DIR/$sname
        cp $FILEDIR/printtoken.c $LOCAL_DIR/$sname
    fi
done
if [[ $zipFound -eq 1 ]]; then
    echo "zipped package found!"
fi
