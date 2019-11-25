#! /bin/bash

TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
SUBDIR=$AUTOGRADERDIR/$1_gradingDir/*
TEST_GRAPH_DIR=$AUTOGRADERDIR/graph1_test
SAMPLE_GRAPH_DIR=$AUTOGRADERDIR/graph1_sample
TEST_PASREC_DIR=$AUTOGRADERDIR/pasrec_test
SAMPLE_PASREC_DIR=$AUTOGRADERDIR/pasrec_sample


gradeUnittest()
{
    ##
    ## $1 executable file name
    ## $2 folder (full path) containing tests
    ## $3 folder (full path) containing samples
    ##
    for entry in $2/*
    do
        testN=$(basename "$entry")
        testN="${testN%.*}"
        echo "testing $testN: "
        $1 < $entry | sed -n "/# ------------------------- begin Your code -----------------------------/,//p" > tmp_result

        if [ -s tmp_result ]
        then
            DIFF=$(diff -w $3/"$testN.sample" tmp_result)
            if [ "$DIFF" != "" ]
            then
                diff -w $3/"$testN.sample" tmp_result
            else
                echo "PASS!"
            fi
        else
            echo "Empty Output!"
        fi
    done
    rm tmp_result
}



gradeCodegen()
{
    ##
    ## $1 the executable
    ##
    echo "################### graph1.pas ######################"
    gradeUnittest $1 $TEST_GRAPH_DIR $SAMPLE_GRAPH_DIR

    echo "################### pasrec.pas ######################"
    gradeUnittest $1 $TEST_PASREC_DIR $SAMPLE_PASREC_DIR

}


gradeSingleStudent()
{
    echo "######################  $WHO  #########################"
    ##
    ## Compile student's code according to the submisions
    ##
    ## Then run the parser/parsec on trivb.pas
    ## Direct the result into a file to be processed
    
    if [[ -f "parse.y" ]]; then
        if [[ -f "lexan.l" ]]; then
            make compiler &> dump
            if [[ -f "compiler" ]]; then
                gradeCodegen ./compiler 
            else
                echo "Compilation error, compiler not found!"
            fi
        else
            echo "lexan.l not found! Copying from p2 ... "
            cp $AUTOGRADERDIR/p2_gradingDir/$WHO/lexan.l ./
            gradeSingleStudent
        fi
    elif [[ -f "parsc.c" ]]; then
        make compc &> dump
        if [[ -f "compc" ]]; then
            gradeCodegen ./compc
        else
            echo "Compilation error, compc not found!"
        fi
    else
        echo "Parser file (parse.y or parsc.c) not found!"
    fi
    
    rm -f result dump
}



##
## Run tests for one student
##
if [[ $# -eq 2 ]]; then
    cd $2
    WHO=$2
    gradeSingleStudent
    cd $TOP_DIR
elif [[ $# -eq 1 ]];then
    ##
    ## Run tests for all students in $1_gradingDir/
    ##
    for student in $SUBDIR
    do
        cd $student
        WHO=${student##*/}
        gradeSingleStudent
        cd $TOP_DIR
    done
else
    echo "Usage: ./codegen_autograder.sh px [studentDir]"
fi
