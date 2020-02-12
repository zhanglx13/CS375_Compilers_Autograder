#! /usr/bin/env bash

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

AUTOGRADERDIR=$(pwd)
TESTS=$AUTOGRADERDIR/test_p1/*
SAMPLEDIR=$AUTOGRADERDIR/sample_$1
SUBDIR=~/CS375_gradingDir/*
FILEDIR=$AUTOGRADERDIR/cs375_minimal
if [[ $1 == "p1" ]];then
    EXE=lexanc
elif [[ $1 == "p2" ]];then
    EXE=lexer
fi

gradeSingleStudent()
{
    echo "######################  $WHO  #########################"
    wronglines=0
    make $EXE &> compilation_dump
    if [[ -f "$EXE" ]];then
        echo "scantst:"
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
        ##
        ## The wronglines variable makes little sense because it contains several
        ## false alert:
        ## 1. overflow message
        ## 2. the 6th digit in the mantissa
        ##
        ## I do not have plans to exclude these false alert in the near future.
        ## 
        if [[ $wronglines -eq 0 ]]; then
            echo -e "\xE2\x9C\x94"
        else
            echo "Wrong lines: $wronglines"
        fi
        ## Test graph1.pas
        ##
        ## Note that we need to empty DIFF before using it for testing graph1.pas
        ## because DIFF=$(diff x y) will not update DIFF's content if x and y is
        ## the same. In this case, the DIFF for the graph1.pas test will be the same
        ## as the DIFF for the last test case of scantst.pas, which is scantst_9
        ##
        DIFF=""
        echo "graph1:"
	    ./$EXE < $FILEDIR/graph1.pas &> result
        if [[ $1 == "p1" ]]; then
            DIFF=$(diff result graph1.lex)
        elif [[ $1 == "p2" ]]; then
            DIFF=$(diff result graph1.lexer)
        fi
        if [ "$DIFF" != "" ]
        then
            echo "$DIFF"
        else
            echo -e "\xE2\x9C\x94"
        fi
        rm *.o result $EXE
    else
        echo "Does not compile"
    fi
}


##
## Start the autograder
##
declare -A pArray
pArray=(
    [p1]=1
    [p2]=1
)

if [[ $# -eq 0 ]] || [[ $# -gt 2 ]];
then
    echo "Must specify one or two args"
    echo "Usage: ./lexer_autograder.sh px [studentDir]"
else
    ##
    ## First check if the first arg is p1 or p2
    ##
    if [[ ${pArray[$1]} ]];
    then
        if [[ $# -eq 2 ]];
        then
            ##
            ## single mode
            ##
            cd $2
            WHO=$2
            gradeSingleStudent
        else
            ##
            ## all mode
            ##
            for student in $SUBDIR
            do
                cd $student
                WHO=${student##*/}
                gradeSingleStudent
            done
        fi
    else
        echo "The first arg of ./parser_autograder.sh should only be p1 or p2"
    fi
fi
