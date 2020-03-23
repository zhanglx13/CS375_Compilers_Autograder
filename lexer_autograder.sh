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



##
## Global array defining overflow cases
##
declare -A sArray
sArray=(
    [20]=1
    [21]=1
    [50]=1
    [52]=1
    [53]=1
)
##
## This function checks the special cases of p1
##
## 1. Integer overflow: scantst_20, 21
## 2. Floating overflow: scantst_50, 52, 53
## 3. Floating number 3.141592ex vs 3.141593ex
##
## Input:
##   $1 testname, in the form of scantst_xx or trivb_1
##   $2 student output file
##   $3 sample output file
##
checkSpecial()
{
    cmp=0
    ##
    ## Get the test case number, pay attention to trivb_1
    ##
    if [[ $1 == "trivb_1" ]]; then
        num=0
    else
        num=${1:8}
    fi
    ##
    ## Checks if the sample output contains scientific numbers
    ##
    cnt=$(egrep -c '*[0-9]e[+|-]*' $3)
    if [[ ${sArray[$num]} ]]; then
        ##
        ## Overflow special cases
        ##
        ##
        ## First, get the error message
        ##
        errMsg=$(egrep -v tokentype $2 | egrep -v Started)
        if [[ $errMsg == "" ]]; then
            ##
            ## If overflow message not found, then print error
            ##
            echo ""
            echo "$1"
            echo ""
            echo "=> Empty error message!!!"
            ((wronglines++))
            ##
            ## Note that for scantst_20, there are three
            ## more lines after the overflowed integer.
            ## However, we do not check them since we already
            ## found the error message missing.
            ##
        else
            ##
            ## If error message exists, then remove lines
            ## relevant to the overflow error
            ##
            ## grep tokentype lines and remove the first
            ##
            egrep 'tokentype' $2 | awk 'NR>1' > result_tmp
            egrep 'tokentype' $3 | awk 'NR>1' > sample_tmp
            DIFF=$(diff result_tmp sample_tmp)
            if [[ $DIFF != "" ]]; then
                echo ""
                echo "$1"
                echo ""
                echo "$DIFF"
                ((wronglines++))
            fi
        fi
    elif [[ $cnt -gt 0 ]]; then
        ##
        ## The sample of this case has one and only one
        ## scientific number
        ##
        ## First check if student's output also has
        ## only one scientific number
        ##
        myCnt=$(egrep -c '*[0-9]e[+|-]*' $2)
        if [[ $myCnt -ne $cnt ]];then
            cmp=1
        else
            ##
            ## Then we should take a close look at the
            ## line containing the scientific number
            ##
            egrep '*[0-9]e[+|-]*' $3 > sampleLine
            egrep '*[0-9]e[+|-]*' $2 > myLine
            ##
            ## Get tokentype, type, mantissa, and exponent
            ##
            ## Note that we need to handle mantissa carefully
            ## since it is allowed to have an error less than 0.000001
            ##
            ## For the rest fields, we just compare them as a string
            ## since we need exact match for those fields
            my_mantissa=$(awk '{print $5}' myLine | awk -Fe '{print $1}')
            myOutput="$(cat myLine)"
            myOutput=${myOutput/$my_mantissa/}
            sample_mantissa=$(awk '{print $5}' sampleLine | awk -Fe '{print $1}')
            sampleOutput="$(cat sampleLine)"
            sampleOutput=${sampleOutput/$sample_mantissa/}
            ##
            ## Compare each component
            ##
            mantissa_err=$(echo "$sample_mantissa - $my_mantissa" | bc)
            if [[ $(echo "$mantissa_err > 0.000001 || $mantissa_err < -0.000001" | bc) -eq 1 ]];then
                cmp=1
            fi
            if [[ "$myOutput" != "$sampleOutput" ]]; then
                cmp=1
            fi
        fi
    else
        ##
        ## Other cases, just compare the outputs
        ##
        cmp=1
    fi
    ##
    ## Normal compare
    ##
    if [[ $cmp -eq 1 ]]; then
        DIFF=$(diff $2 $3)
        if [[ $DIFF != "" ]]; then
            echo ""
            echo "$1"
            echo ""
            echo "$DIFF"
            ((wronglines++))
        fi
    fi
    ##
    ## Clean up
    ##
    rm -f result_tmp sample_tmp myLine sampleLine
}


gradeSingleStudent()
{
    echo "######################  $WHO  #########################"
    wronglines=0
    make $EXE &> compilation_dump
    if [[ -f "$EXE" ]];then
        echo ">>>>>>>>>>"
        echo "scantst:"
        echo ">>>>>>>>>>"
        for testInput in $TESTS
        do
            xbase=${testInput##*/}
            xpref=${xbase%.*}
            ##
            ## Run the lexer and redirect stdout and stderr to result
            ##
            ## Note that if the program seg faults, the signal received
            ## by the program is redirected to result. But the signal
            ## received by bash is not. Therefore, we need to use Msg
            ## to wrap the signal message
            ##
            Msg=$(./$EXE < $testInput &> result)
            ##
            ## Then we check if the exit code of the last command
            ## is 139, which is SIGNAL 11, i.e. segmentation fault
            ## If so, we simply print segfault for this test
            ##
            if [[ $? -eq 139 ]]; then
                ##
                ## Seg fault
                ##
                echo ""
                echo "$xpref"
                echo ""
                echo "=> Seg fault"
                ((wronglines++))
            else
                DIFF=$(diff result $SAMPLEDIR/$xpref.sample)
                if [ "$DIFF" != "" ]
                then
                    if [[ $EXE -eq "lexanc" ]]; then
                        checkSpecial $xpref result $SAMPLEDIR/$xpref.sample
                    else
                        echo ""
                        echo "$xpref"
                        echo ""
                        echo "$DIFF"
                        ((wronglines++))
                    fi
                fi
            fi
        done
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
        echo ""
        echo ">>>>>>>>>>"
        echo "graph1:"
        echo ">>>>>>>>>>"
	    Msg=$(./$EXE < $FILEDIR/graph1.pas &> result)
        ##
        ## Check if the last command seg faults
        ##
        if [[ $? -eq 139 ]]; then
            echo "=> Seg fault"
        else
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
