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

##
## Generate one possible set of samples using the solution
##
## The samples are saved in sample_p2/
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
#     ./lexer < $entry > "./sample_p2/$xpref.sample"
# done

TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
TESTS=$AUTOGRADERDIR/test_p1/*
SAMPLEDIR=$AUTOGRADERDIR/sample_$1
SUBDIR=$AUTOGRADERDIR/$1_gradingDir/*
FILEDIR=$AUTOGRADERDIR/cs375_minimal
if [[ $1 == "p1" ]];then
    EXE=lexanc
elif [[ $1 == "p2" ]];then
    EXE=lexer
fi

gradeSingleStudent()
{

    echo "############  $WHO  ###############"
    wronglines=0
    make $EXE &> dump
    if [[ -f "$EXE" ]];then
        for testInput in $TESTS
        do
            xbase=${testInput##*/}
            xpref=${xbase%.*}
            ./$EXE < $testInput &> result
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
	    ./$EXE < $FILEDIR/graph1.pas &> result
        if [[ $1 == "p1" ]]; then
            diff result $FILEDIR/graph1.lex
        elif [[ $1 == "p2" ]]; then
            diff result $FILEDIR/graph1.lexer
        fi
        rm *.o result $EXE
    else
        echo "Does not compile"
    fi
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
    echo "Usage: ./autograder.sh px [studentDir]"
fi





