#! /bin/bash

CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder

copyifnotexist(){
    if [ ! -e "$1" ]; then
        cp $CS375DIR/cs375/$1 ./
    fi
}

cd p1_gradingDir

for entry in ./*
do
    cd $entry
    echo $entry
    for subentry in ./*
    do
        if [[ $subentry == *lexanc*.c ]]; then
            mv $subentry lexanc.c
        fi
        if [[ $subentry == *lexan*.h ]]; then
            mv $subentry lexan.h
        fi
        if [[ $subentry == *scanner*.c ]]; then
            mv $subentry scanner.c
        fi
        if [[ $subentry == *token*.h ]]; then
            mv $subentry token.h
        fi
        if [[ $subentry == *lexandr*.c ]]; then
            mv $subentry lexandr.c
        fi
	if [[ $subentry == *printtoken*.c ]]; then
	    mv $subentry printtoken.c
	fi
    done
    cp $AUTOGRADERDIR/makefile ./
    copyifnotexist lexandr.c
    copyifnotexist token.h
    copyifnotexist lexan.h
    copyifnotexist scanner.c
    copyifnotexist printtoken.c
    copyifnotexist graph1.pas
    copyifnotexist graph1.lex
    copyifnotexist scantst.pas
    copyifnotexist scantst.sample
    cd ..
done
