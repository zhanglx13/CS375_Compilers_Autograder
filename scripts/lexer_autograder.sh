#! /usr/bin/env bash

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
printHeader=0


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

repeatPrint()
{
    # $1 char to repeat
    # $2 times
    for i in `seq 1 $2`
    do
        printf "$1"
    done
}
printName()
{
    # $1 name to print
    space=20
    name="$1"
    printf "||\n||"
    repeatPrint " " $space
    printf "%s" $WHO
    repeatPrint " " $space
    printf "\n||\n"
}

printTest()
{
    # $1 test to print
    # $2 the message to print on the same line of the test name
    space=2
    name="$1"
    printf "|\n|"
    repeatPrint " " $space
    printf "%s  $2\n|\n" "$name"
}

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
    cnt=$($EGREP -c '*[0-9]e[+|-]*' $3)
    if [[ ${sArray[$num]} ]]; then
        ##
        ## Overflow special cases
        ##
        ##
        ## First, get the error message
        ##
        errMsg=$($EGREP -v tokentype $2 | $EGREP -v Started)
        if [[ $errMsg == "" ]]; then
            ##
            ## If overflow message not found, then print error
            ##
            if [[ $printHeader -eq 0 ]];then
                printTest " "
                printHeader=1
            fi
            printf "%s\n" $1
            echo "  Empty error message!!!"
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
            $EGREP 'tokentype' $2 | awk 'NR>1' > result_tmp
            $EGREP 'tokentype' $3 | awk 'NR>1' > sample_tmp
            DIFF=$(diff result_tmp sample_tmp)
            if [[ $DIFF != "" ]]; then
                if [[ $printHeader -eq 0 ]];then
                    printTest " "
                    printHeader=1
                fi
                printf "%s\n" $1
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
        myCnt=$($EGREP -c '*[0-9]e[+|-]*' $2)
        if [[ $myCnt -ne $cnt ]];then
            cmp=1
        else
            ##
            ## Then we should take a close look at the
            ## line containing the scientific number
            ##
            $EGREP '*[0-9]e[+|-]*' $3 > sampleLine
            $EGREP '*[0-9]e[+|-]*' $2 > myLine
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
            if [[ $printHeader -eq 0 ]];then
                printTest " "
                printHeader=1
            fi
            printf "%s\n" $1
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
    wronglines=0
    make $EXE &> compilation_dump
    if [[ -f "$EXE" ]];then
        #printTest "scantst"
        printHeader=0
        for testInput in $TESTS
        do
            xbase=${testInput##*/}
            xpref=${xbase%.*}
            testF=${xpref%_*}
            ##
            ## Run the lexer and redirect stdout and stderr to result
            ##
            ## Note that if the program seg faults, the signal received
            ## by the program is redirected to result. But the signal
            ## received by bash is not. Therefore, we need to use Msg
            ## to wrap the signal message
            ##
            Msg=$($TIMEOUT 3 ./$EXE < $testInput &> result)
            ##
            ## Since we are checking seg fault and time out, the exit status
            ## needs to be saved. Note that $? is the status of the last
            ## executed command.
            ##
            status=$?
            ##
            ## Then we check if the exit code of the last command
            ## is 139, which is SIGNAL 11, i.e. segmentation fault
            ## If so, we simply print segfault for this test
            ##
            if [[ $status -eq 139 ]]; then
                if [[ $printHeader -eq 0 ]];then
                    printTest " "
                    printHeader=1
                fi
                ##
                ## Seg fault
                ##
                printf "%s\n" $xpref
                echo "  Seg fault"
                ((wronglines++))
            ##
            ## The exit status for timed out commands is 124
            ##
            elif [[ $status -eq 124 ]]; then
                if [[ $printHeader -eq 0 ]];then
                    printTest " "
                    printHeader=1
                fi
                ##
                ## Timeout
                ##
                printf "%s\n" $xpref
                echo "  Timeout"
                ((wronglines++))
            else
                DIFF=$(diff result $SAMPLEDIR/$xpref.sample)
                if [ "$DIFF" != "" ]
                then
                    ##
                    ## Since scantst and graph1 tests are merged into the same
                    ## dir, we need to make sure we only check scientific numbers
                    ## for the scantst tests.
                    ##
                    if [[ $EXE -eq "lexanc" ]] && [[ $testF -eq "scantst" ]]; then
                        checkSpecial $xpref result $SAMPLEDIR/$xpref.sample
                    else
                        if [[ $printHeader -eq 0 ]];then
                            printTest " "
                            printHeader=1
                        fi
                        printf "%s\n" $xpref
                        echo "$DIFF"
                        ((wronglines++))
                    fi
                fi
            fi
        done
        if [[ $wronglines -eq 0 ]]; then
            printTest " " "All Good!!"
        else
            echo "Wrong lines: $wronglines"
        fi
        ############################################################################
        ## The testing for graph1.pas is deprecated since graph1 (together with   ##
        ## pasrec.pas) is broken down into individual lines for unit testing.     ##
        ##                                                                        ##
        ## Test graph1.pas                                                        ##
        ##                                                                        ##
        ## Note that we need to empty DIFF before using it for testing graph1.pas ##
        ## because DIFF=$(diff x y) will not update DIFF's content if x and y is  ##
        ## the same. In this case, the DIFF for the graph1.pas test will be the   ##
        ## same as the DIFF for the last test case of scantst.pas,                ##
        ## which is scantst_9                                                     ##
        ##                                                                        ##
        # DIFF=""                                                                 ##
        # printHeader=0                                                           ##
	    # Msg=$($TIMEOUT 3 ./$EXE < $FILEDIR/graph1.pas &> result)                ##
        # status=$?                                                               ##
        # ##                                                                      ##
        # ## Check if the last command seg faults                                 ##
        # ##                                                                      ##
        # if [[ $status -eq 139 ]]; then                                          ##
        #     printTest "graph1 " "Seg fault!!"                                   ##
        # elif [[ $status -eq 124 ]]; then                                        ##
        #     printTest "graph1 " "Timed out!!"                                   ##
        # else                                                                    ##
        #     if [[ $1 == "p1" ]]; then                                           ##
        #         DIFF=$(diff result $FILEDIR/graph1.lex)                         ##
        #     elif [[ $1 == "p2" ]]; then                                         ##
        #         DIFF=$(diff result $FILEDIR/graph1.lexer)                       ##
        #     fi                                                                  ##
        #     if [ "$DIFF" != "" ]                                                ##
        #     then                                                                ##
        #         printTest "graph1 "                                             ##
        #         echo "$DIFF"                                                    ##
        #     else                                                                ##
        #         printTest "graph1 " "All Good!!"                                ##
        #     fi                                                                  ##
        # fi                                                                      ##
        ############################################################################
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

##
## Testing for MacOS
## Check for gnu version of timeout and egrep
##
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ">>>>>>>>> Running the autograder on MacOS <<<<<<<<<<"
    if hash gtimeout 2>/dev/null; then
        TIMEOUT=gtimeout
    else
        echo "Please install gnu-timeout as follows:"
        echo "  brew install coreutils"
        exit 0
    fi
    if hash gegrep 2>/dev/null; then
        EGREP=gegrep
    else
        echo "Please install gnu-grep as follows:"
        echo "  brew install grep"
        exit 0
    fi
else
    TIMEOUT=timeout
    EGREP=egrep
fi

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
            gradeSingleStudent $1
        else
            ##
            ## all mode
            ##
            for student in $SUBDIR
            do
                if [[ -d $student ]]; then
                    cd $student
                    WHO=${student##*/}
                    printName $WHO
                    gradeSingleStudent $1
                fi
            done
        fi
    else
        echo "The first arg of ./parser_autograder.sh should only be p1 or p2"
    fi
fi
