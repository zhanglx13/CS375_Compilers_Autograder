#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##

###########################################################################
##                                                                       ##
## Autograder for project 6 --- codegen,c                                ##
##                                                                       ##
## The autograder can be used for grading all students' code             ##
## (all mode) or a single student's code (single mode)                   ##
## according to the first argument                                       ##
##                                                                       ## 
## Usage: ./codegen_autograder.sh p6|studentDir                          ##
##                                                                       ##
## gradeSingleStudent                                                    ##
##                                                                       ##
##   Both all mode and single mode will call gradeSingleStudent,         ##
##   in which one student's code is compiled according to the            ##
##   files submitted. Then the executable will be passed as              ##
##   the only argument to gradeCodegen.                                  ##
##                                                                       ##
##   Arg:                                                                ##
##     No input. gradeSingleStudent is called after cd'ing into          ##
##     the student's folder                                              ##
##                                                                       ##
##   Compilation mode:                                                   ##
##     1. If parse.y is found, then compile using make compiler          ##
##     2. If parsc.c is found, then compile using make compc             ##
##                                                                       ##
## gradeCodegen                                                          ##
##                                                                       ##
##   Simply call gradeUnittest for both graph1 and pasrec                ##
##                                                                       ##
##   Arg:                                                                ##
##     $1: compiler executable                                           ##
##                                                                       ##
## gradeUnittest                                                         ##
##                                                                       ##
##   Run the compiler executable on each of the unit test in             ##
##   the test folder and compare the result with the                     ##
##   corresponding sample in the sample folder                           ##
##                                                                       ##
##   Args:                                                               ##
##     $1: compiler executable                                           ##
##     $2: test folder full path name                                    ##
##     $3: sample folder full path name                                  ##
##                                                                       ##
##   How to compare for each unit test                                   ##
##     1. [Seg Fault?] Run the compiler executable on the test           ##
##        and redirect the result into a temp file. If $? equals         ##
##        139, then a seg fault signal is received.                      ##
##     2. [No code generated?] Check if there is nothing between         ##
##        /begin Your code/ and /begin Epilogue code/. If so             ##
##        print out "No Code generated!!". This is helped with           ##
##        countLines.                                                    ##
##     3. [first diff] diff sample output after removing all             ##
##        comments in both sample and output. If diff outputs            ##
##        nothing, print out "\xE2\x9C\x94" which is the check           ##
##        mark.                                                          ##
##     4. [second diff] if the output and the sample does not            ##
##        match for the first time, the output has a second              ##
##        chance to match another sample if it exists. The               ##
##        second sample for the same test has a name same as             ##
##        the first sample appended a 0 to the basename of               ##
##        the filename.                                                  ##
##        E.g.                                                           ##
##        For test25.pas, the first sample is named as                   ##
##        test25.sample and the second sample is named as                ##
##        test250.sample.                                                ##
##        Since we always use two digits to represent a test             ##
##        number, e.g. test03.pas instead of test3.pas, the              ##
##        second sample (e.g. test030.sample) will not be                ##
##        confused with any first samples (e.g. test30.sample).          ##
##     5. [Not Match] When the output does not match any of              ##
##        the samples, we print the following two things                 ##
##        a. diff result between sample and output with                  ##
##           comment removed                                             ##
##        b. code between /begin Your code/ and /begin Epilogue code/    ##
##           in the sample                                               ##
##                                                                       ##
##                                                                       ##
## TODO:                                                                 ##
##   1. The output when result does not match can still be               ##
##      hard for grading, especially when student has a lot              ##
##      of small issues. Sometimes I feel like printing the              ##
##      whole student's output also. But this adds info                  ##
##      when student's code does match well. Maybe a heuristic           ##
##      can be used:                                                     ##
##      when the number of diff exceeds a threshold, print               ##
##      student's output also                                            ##
##                                                                       ##
###########################################################################
TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
TEST_GRAPH_DIR=$AUTOGRADERDIR/graph1_test
SAMPLE_GRAPH_DIR=$AUTOGRADERDIR/graph1_sample
TEST_PASREC_DIR=$AUTOGRADERDIR/pasrec_test
SAMPLE_PASREC_DIR=$AUTOGRADERDIR/pasrec_sample


countLines()
{
    ##
    ## $1 is the output file
    ##
    sed -n '/begin Your code/,/begin Epilogue code/p' $1 | wc -l
}

gradeUnittest()
{
    ##
    ## $1 executable file name
    ## $2 folder (full path) containing tests
    ## $3 folder (full path) containing samples
    ##
    zero=0
    pass=0
    for entry in $2/*
    do
        testN=$(basename "$entry")
        testN="${testN%.*}"
        echo "@@@@@@@@@@@@@@@@@@@@ testing $testN: @@@@@@@@@@@@@@@@@@@"
        Msg=$($1 < $entry)
        ##
        ## Check seg fault 
        ##
        if [[ $? -eq 139 ]];then
            echo "Seg Fault!!"
            pass=2
        else
            ##
            ## If no seg fault, check syntax error
            ##
            $1 < $entry | sed -n "/begin Your code/,//p" > tmp_result
            syntaxErr=$(grep "syntax error" tmp_result)
            if [[ $syntaxErr ]]; then
                echo "found syntax error!!"
            else
                ##
                ## If no syntax error, check empty output
                ##
                if [ -s tmp_result ]
                then
                    ##
                    ## First we check if the output is empty between the markers
                    ##
                    nL=$(countLines tmp_result)
                    if [ $nL == "2" ]
                    then
                        echo "No Code Generated!!"
                    else
                        ##
                ## When diffing, we want to ignore comments
                ##
                sed '/^[[:blank:]]*#/d;s/#.*//' tmp_result > output
                sed '/^[[:blank:]]*#/d;s/#.*//' $3/"$testN.sample" > sample
                DIFF=$(diff -w sample output)
                if [ "$DIFF" != "" ]
                then
                    ##
                    ## If the output does not match the sample
                    ## Try to see if there is an alternative sample
                    ##
                    if [ -f $3/$testN$zero.sample ]; then
                        sed '/^[[:blank:]]*#/d;s/#.*//' $3/$testN$zero.sample > sample
                        DIFF1=$(diff -w sample output)
                        if [ "$DIFF1" != "" ]
                        then
                            pass=0  
                        else
                            pass=1
                        fi
                    else
                        pass=0
                    fi
                else
                    pass=1
                fi
                    fi
                else
                    echo "Empty Output!!"
                    pass=0
                fi
            fi
        fi

        if [ $pass == 0 ]
        then
            echo ">>>>>>>> DIFF <<<<<<<<"
            diff -w sample output
            echo ">>>>>>>> Sample <<<<<<<<"
            ##
            ## When they are different, we might want to check the
            ## sample. But only the important section of the sample
            ##
            sed -n '/begin Your code/,/begin Epilogue code/p' $3/"$testN.sample" | sed '1d;$d' 
        elif [ $pass == 1 ]
        then
            ##
            ## When PASS, print out the check mark
            ##
            echo -e "\xE2\x9C\x94"
        fi
    done
    rm tmp_result output sample
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

    if [[ -f "parse.y" ]]; then
        ## disable parser-tracing function
        sed -i 's/yydebug/\/\/yydebug/g' parse.y
        ## Canonicalize the parse tree before calling gencode
        sed -i 's/gencode/exprCanonicalization(parseresult);gencode/g' parse.y
        make compiler &> dump
        ## Reverse source code modification after compilation
        sed -i 's/exprCanonicalization(parseresult);gencode/gencode/g' parse.y
        sed -i 's/\/\/yydebug/yydebug/g' parse.y
        if [[ -f "compiler" ]]; then
            gradeCodegen ./compiler 
        else
            echo "Compilation error, compiler not found!"
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
## Start autograding process
##
if [[ $# -eq 1 ]];
then
    if [ $1 == "p6" ];
    then
        ##
        ## $1 is one of project number
        ## invoke the all mode
        ##
        SUBDIR=~/CS375_gradingDir/*
        for student in $SUBDIR
        do
            cd $student
            WHO=${student##*/}
            gradeSingleStudent
            cd $TOP_DIR
        done
    else
        ##
        ## $1 is the student dir
        ## invoke the single mode
        ##
        cd $1
        WHO=$1
        gradeSingleStudent
        cd $TOP_DIR
    fi
else
    echo "Usage: ./codegen_autograder.sh p6|studentDir"
fi
