#! /bin/bash

##
## Read scantst.pas and write each line
## as a separate file name as
##     scantst_lineno.pas
## where lineno is replaced by the line number
##
## Empty lines are ignored
##
## The result files are save in test_p1/
##

# lineno=1
# while read -r line
# do
#     if [ ! -z "$line" ]
#     then
#         echo "$lineno: $line"
#         echo "$line" > "./test_p1/scantst_$lineno.pas"
#     fi
#     ((lineno++))
# done < scantst.pas


##
## Generate one possible set of samples using the solution
##
## The samples are saved in sample_p1/
##

# for entry in ./test_p1/*
# do
#     ##
#     ## Get file name only without path nor extension
#     ## https://stackoverflow.com/questions/3362920/get-just-the-filename-from-a-path-in-a-bash-script
#     ##
#     xpath=${entry%/*}
#     xbase=${entry##*/}
#     xfext=${xbase##*.}
#     xpref=${xbase%.*}
#     ./lexanc < $entry > "./sample_p1/$xpref.sample"
# done

TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
TESTS=$AUTOGRADERDIR/test_p1/*
SAMPLEDIR=$AUTOGRADERDIR/sample_p1
SUBDIR=$AUTOGRADERDIR/p1_gradingDir/*

gradeSingleStudent()
{

    echo "############  $WHO  ###############"
    wronglines=0
    make lexanc &> dump
    if [[ -f "lexanc" ]];then
        for testInput in $TESTS
        do
            xbase=${testInput##*/}
            xpref=${xbase%.*}
            ./lexanc < $testInput &> result
            DIFF=$(diff result $SAMPLEDIR/$xpref.sample)
            if [ "$DIFF" != "" ]
            then
                echo "$xpref"
                echo "$DIFF"
                ((wronglines++))
            fi
        done
        echo "Wrong lines: $wronglines"
        ## Test graph1.pas
        echo "graph1:"
	    ./lexanc < $TOP_DIR/graph1.pas &> result
        diff result $TOP_DIR/graph1.lex
        rm *.o result  lexanc
    else
        echo "Does not compile"
    fi
}

##
## Run tests for one student
##
if [[ $# -eq 1 ]]; then
    cd $1
    WHO=$1
    gradeSingleStudent
    cd $TOP_DIR
else
##
## Run tests for all students in p1_gradingDir/
##
    for student in $SUBDIR
    do
        cd $student
        WHO=${student##*/}
        gradeSingleStudent
        cd $TOP_DIR
    done
fi





