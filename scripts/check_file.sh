#! /usr/bin/env bash

#set -e

##
## Check files in autograder/cs375_minimal/ to see if they
## are up to date with files in /projects/cs375
##

## Get files from the server
#scp -r lxzhang@aida.cs.utexas.edu:/projects/cs375 ./
## Check

## $1: folder that contains the latest files, must be absolute path
cd ../cs375_minimal/

declare -A newFile
newFile=(
    [makefile]=1
    [pprint.h]=1
    [pprint.c]=1
    [printtoken.c]=1
)

for file in ./*
do
    file=${file#./}
    echo "processing $file"
    if [[ ${newFile[$file]} != 1 ]]; then
        echo "diff $file"
        diff $file $1/$file
    fi
done
