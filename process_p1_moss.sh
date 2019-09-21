#! /bin/bash

cd p1_gradingDir

for entry in ./*
do
    cd $entry
    echo $entry
    cp lexanc.c ../../moss_p1/$entry
    cd ..
done
