#!/usr/bin/env bash

AUTOGRADER=$(pwd)

declare -A pArray
pArray=(
    [p1]=1
    [p2]=1
    [p3]=1
    [p4]=1
    [p5]=1
    [p6]=1
)

if [[ $# -eq 0 ]]; then
    echo "Please select a project px"
else
    ##
    ## For security reasons, we want to restrict
    ## $1 to be one of the following values
    ## {p1, p2, p3, p4, p5, p6}
    ##
    if [[ ${pArray[$1]} ]];
    then
        echo "Preparing for project $1"
        ##
        ## Extract the zip in the home dir
        ##
        cd ~/
        if [ -d "submissions_$1" ];
        then
            rm -r submissions_$1
        fi
        dtrx "$AUTOGRADER/submissions_$1.zip"
        ##
        ## We need to go back to the autograder_dir
        ##
        cd $AUTOGRADER
        ./scripts/copy.sh $1
    else
        echo "Please specify project as one of (p1,p2,p3,p4,p5,p6)"
    fi
fi
