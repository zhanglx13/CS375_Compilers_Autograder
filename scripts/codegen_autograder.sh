#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##

###########################################################################
##
## Autograder for project 6 --- codegen,c
##
## Usage: ./codegen_autograder.sh -p 6 - d WD [-t tn]
##
## gradeSingleStudent [tn]
##
##   The student's code is compiled according to the files submitted file.
##   Then the executable, as well as test dir, sample dir, and may a unit test
##   number will be passed to gradeUnittest.
##
##   Arg:
##     tn: if specified, only the unit test will be graded.
##
##   Compilation mode:
##     1. If parse.y is found, then compile using make compiler
##     2. If parsc.c is found, then compile using make compc
##
## gradeUnittest
##
##   Run the compiler executable on each of the unit test (or only the unit test
##   that is specified) in the test folder and compare with the result with the
##   corresponding sample in the sample folder.
##
##   Args:
##     $1: compiler executable
##     $2: test folder full path name
##     $3: sample folder full path name
##     $4: If specified, gives the unit test number to grade.
##
##   How to grade each unit test
##     1. [Error?] Run the compiler executable on the test and redirect the
##        result into a temp file. If $? != 0, then there is an error and the message
##        can be found by indexing in the exitErr array using $?.
##     2. [No assembly code generated?] Check if there is nothing in the assembly
##        code section. If so, print out "No Assembly Code Generated!!" and
##        "<error message>" if there is an error.
##        This is helped with countAsmLines.
##     3. [No assembly code found?] If "begin Your code" line is not printed, there
##        must be an error at an earlier place. If so, print out "No Assembly Found!!"
##        and "<error message>" if there is an error.
##     4. [first diff] diff sample output after removing all comments in both
##        sample and output. If diff outputs nothing, set pass=1.
##     5. [second diff] if the output and the sample does not match for the first
##        time, the output has a second chance to match another sample if it exists.
##        The second sample for the same test has a name same as the first sample
##        appended a 0 to the basename of the filename. E.g. For test25.pas, the
##        first sample is named as test25.sample and the second sample is named as
##        test250.sample. Since we always use two digits to represent a test number,
##        e.g. test03.pas instead of test3.pas, the second sample
##        (e.g. test030.sample) will not be confused with any first samples
##        (e.g. test30.sample).
##     6. [Not Match] When the output does not match any of the samples, we print
##        the following:
##        a. diff result between sample and output with comment removed.
##        b. Student's output if in single test mode.
##        b. code between /begin Your code/ and /begin Epilogue code/ in the sample.
##        c. A report summarizing wrong lines of the assembly code.
##     7. [Empty output?] When gencode is commented in parse.y, the output is
##        empty. In this case, the script does the following:
##        a. back up parse.y
##        b. remove /*  */ around gencode
##        c. Remove // before gencode() at the same line
##        d. rerun the autograder.
##        Note that rerun will happen iff there is no error.
##        This means rerun will only happen when grading the very first test if it
##        is necessary.
##
#########################################################################
TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
TEST_DIR=$AUTOGRADERDIR/test_p6
SAMPLE_DIR=$AUTOGRADERDIR/sample_p6

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
    # $3 err message if there is any
    space=1
    printf "==>"
    repeatPrint " " $space
    if [[ $3 != "" ]]; then
        echo "$1  $2  <$3>"
    else
        echo "$1  $2"
    fi
}

printBreak()
{
    ##
    ## $1: half the length of the break
    ## $2: message to print
    ##
    printf "    "
    repeatPrint "$" $1 ## light horizontal line
    printf " $2 "
    repeatPrint "$" $1
    printf "\n"
}

countAsmLines()
{
    ##
    ## $1 is the output file
    ##
    cp $1 tmp_output
    $SED -n '/begin Your code/,/begin Epilogue code/p' tmp_output |
        $SED '/begin Your code/d' |
        $SED '/begin Epilogue code/d' | $WC -l
    rm tmp_output
}

checkErr()
{
    ##
    ## $1 is the exit code of the previous command
    ## It tries to find the exit code in exitErr array
    ## and return the message if found.
    ##
    found=0
    for key in "${!exitErr[@]}"
    do
        if [[ $key -eq $1 ]];then
            echo "${exitErr[$key]}"
            found=1
        fi
    done
    if [[ $found -eq 0 ]];then
        echo "Unknown exit code $1"
    fi
}

gradeUnittest()
{
    ##
    ## $1 executable file name
    ## $2 folder (full path) containing tests
    ## $3 folder (full path) containing samples
    ## $4 if exist, specify the single unit test to run ==> single test mode
    ##
    if [[ $# -eq 4 ]]; then
        unitTestNum=$4
    fi
    zero=0
    pass=0
    deadline=5
    for entry in $2/*
    do
        testN=$(basename "$entry")
        testN="${testN%.*}"
        num=${testN#test}
        if [[ $# -eq 4 ]] && [[ ${num#0} -ne ${unitTestNum#0} ]]; then
            continue;
        fi
        testNPoints="$testN (${points[$num]})"
        ##
        ## Check if there is any error
        ##
        Msg=$($TIMEOUT $deadline $1 < $entry &> tmp_err)
        status=$?
        errMsg=""
        if [[ $status -ne 0 ]];then
            errMsg=$(checkErr $status)
            #echo "any error: $errMsg"
        fi
        ##
        ## Early return if timeout
        ##
        if [[ $status -eq 124 ]]; then
            printTest "$testNPoints" "Program takes longer than $deadline seconds to finish!!" "$errMsg"
            continue;
        fi
        ##
        ## We can get the assembly code regardless of the error
        ##
        ## Note that we do not need to check syntax error here.
        ## The rationale is that when syntax error happens in the parsing
        ## phase, there will always be a seg fault when gencode is called.
        ## Therefore, the syntax error was caught in the previous case.
        ##
        ##
        ## Check this post to learn why we need stdbuf to set the stdout
        ## to be unbuffered when we want to redirect the output to a file
        ## while a seg fault exists
        ## https://stackoverflow.com/questions/52468549/bash-how-to-assign-output-of-command-that-ends-with-segmentation-fault-to-varia
        ##
        Msg=$(stdbuf -o0 $1 < $entry &> tmp_raw_result)
        ##
        ## tmp_result does not include error messages
        ##
        { stdbuf -o0 $1 < $entry > tmp_no_err; } 2> /dev/null
        $SED -n "/begin Your code/,//p" tmp_no_err > tmp_result
        ##
        ## Check empty output
        ##
        if [ -s tmp_result ]
        then
            ##
            ## First we check if the output is empty between the markers
            ##
            nL=$(countAsmLines tmp_result)
            if [ $nL == "0" ]
            then
                printTest "$testNPoints" "No Assembly Code Generated!!" "$errMsg"
                pass=2
            else
                ##
                ## When diffing, we want to ignore comments
                ##
                if [[ $status -ne 0 ]]; then
                    ##
                    ## When there is an error, we only compare the assembly code
                    ## between begin and end
                    ##
                    $SED -n '/begin Your code/,/begin Epilogue code/p' $3/"$testN.sample" > sample
                    $SED -i '/^[[:blank:]]*#/d;s/#.*//' sample
                    $SED -n -i '/begin Your code/,/begin Epilogue code/p' tmp_result
                else
                    $SED '/^[[:blank:]]*#/d;s/#.*//' $3/"$testN.sample" > sample
                fi
                $SED '/^[[:blank:]]*#/d;s/#.*//' tmp_result > output
                DIFF=$(diff -w sample output)
                if [ "$DIFF" != "" ]
                then
                    ##
                    ## If the output does not match the sample
                    ## Try to see if there is an alternative sample
                    ##
                    if [ -f $3/$testN$zero.sample ]; then
                        if [[ $segFault -eq 1 ]]; then
                            $SED -n '/begin Your code/,/begin Epilogue code/p' $3/"$testN$zero.sample" > sample
                            $SED -i '/^[[:blank:]]*#/d;s/#.*//' sample
                        else
                            $SED '/^[[:blank:]]*#/d;s/#.*//' $3/$testN$zero.sample > sample
                        fi
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
        elif [[ $status -ne 0 ]]; then
            printTest "$testNPoints" "No Assembly Code Found!!" "$errMsg"
            pass=2
        elif [[ $rerun -eq 0 ]]; then
            ##
            ## Empty output usually means gencode is commented out in the
            ## main(). Here we try to uncomment gencode in parse.y and
            ## rerun the autograder.
            ## We only rerun if we haven't done so
            ##
            echo "Empty Output ==> gencode might be commented out!!"
            if [[ "$1" == "./compiler" ]]; then
                echo "  ... backup parse.y --> parse_orig.y ..."
                cp parse.y parse_orig.y
                echo "  ... uncomment gencode in parse.y ..."
                #########################################################################
                ## The following two commands use GNU Sed, which has some              ##
                ## extensions over the standard sed. Therefore, if MacOS               ##
                ## is used, make sure to install the gnu-sed.                          ##
                ##                                                                     ##
                ## Step 1: remove /*  */ around gencode                                ##
                ##                                                                     ##
                ## sed commands                                                        ##
                ## 1. This command works for multiple lines                            ##
                ## 2. 1{h;d} For the first line, put it into the hold space (h)        ##
                ##    and move on the next cycle without printing the pattern (d)      ##
                ## 3. For other lines, append the pattern into the hold space (H)      ##
                ##    and move on to the next cycle without printing the pattern (d)   ##
                ## 4. For the last line, swap contents in pattern space and hold       ##
                ##    space. And then do the replace.                                  ##
                ## 5. For the replace, [^a-zA-Z] makes it not match any comments       ##
                ##    before the gencode() line. Remember that sed regex matches       ##
                ##    the longest string.                                              ##
                #########################################################################
                $SED -n -i '1{h;d}; H;$!d; x ; s|/\*[^a-zA-Z]*\(gencode.*;\)[\n ]*\*/|\1|;p' parse.y
                #########################################################################
                ## Step 2: Remove // before gencode() at the same line                 ##
                ##                                                                     ##
                ## sed commands                                                        ##
                ## 1. This only works for the gencode() line.                          ##
                ## 2. This command removes anything between // and gencode             ##
                ## 3. This command removes anything after gencode();                   ##
                #########################################################################
                $SED -i 's|^\([ ]*\)//.*\(gencode.*;\).*|\1\2|' parse.y
                echo "  ... rerun the autograder ..."
                CURDIR=$(pwd)
                cd $AUTOGRADERDIR
                if [[ $# -eq 4 ]]; then
                    ./scripts/codegen_autograder.sh $CURDIR 1 $4
                else
                    ./scripts/codegen_autograder.sh $CURDIR 1
                fi
            else
                echo "  ... parsc.c needs to be fixed ..."
                echo "  ... please fix it manually ..."
            fi
            ##
            ## terminate the autograder when re-run completes
            ##
            exit 0
        fi

        if [ $pass == 0 ]
        then
            if [[ $status -ne 0 ]]; then
                printTest "$testNPoints" "" "$errMsg"
            else
                printTest "$testNPoints"
            fi
            ##
            ## Count the diff lines and generate a simple report
            ## at the end
            sL=$(countAsmLines $3/"$testN.sample")
            ##
            ## Output diff
            ##
            printBreak 15 DIFF
            diff -w sample output | tee tmp_diff | $SED 's/^/    /'
            ##
            ## tmp_diffN contains d,c, and a diff line numbers only
            ## tmp_sampleN contains the line numbers before d/c/a
            ##
            $SED -n '/[[:digit:]][dca][[:digit:]]/p' tmp_diff > tmp_diffN
            $AWK 'BEGIN {FS="[dca]"}{print $1}' tmp_diffN > tmp_sampleN
            diffL=0
            epilogue=0
            while read -r line
            do
                ##
                ## $beforeN stores the starting line number
                ## $afterN stores the end line number
                ##
                beforeN=${line/,[0-9]*/}
                afterN=${line/[0-9]*,/}
                ##
                ## Check if start line number is less than the total
                ## number of assembly code. If so, increment $result
                ##
                if [[ $(echo "$beforeN <= $sL" | bc) -eq 1 ]];then
                    diffL=$(echo "$diffL+$afterN-$beforeN+1" | bc)
                else
                    ##
                    ## If the diff happens in the epilogue, only set
                    ## the flag
                    ##
                    epilogue=1
                fi
            done < tmp_sampleN
            if [[ $# -eq 4 ]]; then
                printBreak 31 "My Output"
                ##
                ## In single test mode, print parse tree as well as the assembly code
                ##
                Msg=$(stdbuf -o0 $1 < $entry &> tmp_result)
                $SED -n "/program graph1/,/Beginning of Generated Code/p" tmp_result |
                    $SED "/Beginning of Generated Code/d" > tmp_tree
                $SED -n "/begin Your code/,//p" tmp_result > tmp_asm
                cat tmp_tree | $SED 's/^/    /'
                cat tmp_asm | $SED 's/^/    /'
                ##
                ## for some reason tmp_result does not capture the signal message
                ##
                if [[ $status -ne 0 ]]; then
                    echo "    $errMsg"
                fi
                printBreak 33 Sample
                $SED -n '/begin Your code/,//p' $3/"$testN.sample" | $SED 's/^/    /'
                echo ""
            else
                ##
                ## Output sample
                ##
                printBreak 33 Sample
                ##
                ## When they are different, we might want to check the
                ## sample. But only the important section of the sample
                ##
                $SED -n '/begin Your code/,/begin Epilogue code/p' $3/"$testN.sample" |
                    $SED '1d;$d' |
                    cat -n # simpler than the following awk command
                #awk '{print NR ":" $0}'
            fi
            ##
            ## Output a report
            ##
            printBreak 34 Report
            echo "    wrong assembly code lines: $diffL / $sL"
            if [[ $epilogue -eq 1 ]]; then
                echo "    something wrong in literal data section"
            fi
        elif [ $pass == 1 ]
        then
            printTest "$testNPoints" "All Good!!" "$errMsg"
        elif [ $pass == 2 ]
        then
            if [[ $# -eq 4 ]]; then
                printBreak 31 "My Output"
                $SED -n "/program graph1/,//p" tmp_raw_result |
                    $SED -n '/Beginning of Generated Code/{p; :a; N; /begin Your code/!ba; s/.*\n//}; p'|
                    $SED '/Beginning of Generated Code/d' |
                    $SED 's/^/    /'
                if [[ $status -ne 0 ]];then
                    echo "    $errMsg"
                fi
                printBreak 33 Sample
                $SED -n '/begin Your code/,//p' $3/"$testN.sample" | $SED 's/^/    /'
                echo ""
            fi
        fi
    done
    rm -f tmp_* output sample
}


gradeSingleStudent()
{
    ## $1: if exist, specify the single unit test number
    ##
    ## Only print the student's name if the rerun mode is NOT set
    #if [[ $rerun -eq 0 ]]; then
    #    printName $WHO
    #fi
    if [[ -f "codegen.c" ]]; then
        if [[ -f "parse.y" ]]; then
            ## disable parser-tracing function
            $SED -i 's/yydebug/\/\/yydebug/g' parse.y
            ## Canonicalize the parse tree before calling gencode
            $SED -i 's/gencode/exprCanonicalization(parseresult);gencode/g' parse.y
            make compiler &> dump
            ## Reverse source code modification after compilation
            $SED -i 's/exprCanonicalization(parseresult);gencode/gencode/g' parse.y
            $SED -i 's/\/\/yydebug/yydebug/g' parse.y
            if [[ -f "compiler" ]]; then
                if [[ $# -eq 1 ]]; then
                    gradeUnittest ./compiler $TEST_DIR $SAMPLE_DIR $1
                else
                    gradeUnittest ./compiler $TEST_DIR $SAMPLE_DIR
                fi
            else
                echo "Compilation error, compiler not found!"
            fi
        elif [[ -f "parsc.c" ]]; then
            make compc &> dump
            if [[ -f "compc" ]]; then
                gradeUnittest ./compc $TEST_DIR $SAMPLE_DIR
            else
                echo "Compilation error, compc not found!"
            fi
        else
            echo "Parser file (parse.y or parsc.c) not found!"
        fi
    else
        echo "codegen.c not found!"
    fi
    rm -f result dump
}





declare -A points
points=(
    [00]=2
    [01]=2
    [02]=2
    [03]=3
    [04]=3
    [05]=3
    [06]=3
    [07]=3
    [08]=3
    [09]=3
    [10]=3
    [11]=2
    [12]=2
    [13]=2
    [14]=4
    [15]=4
    [16]=4
    [17]=2
    [18]=3
    [19]=3
    [20]=3
    [21]=3
    [22]=4
    [23]=5
    [24]=5
    [25]=6
    [26]=6
    [27]=5
    [28]=5
    [29]=1
    [30]=1
)

declare -A exitErr
##
## reference:
## https://www.geeksforgeeks.org/exit-codes-in-c-c-with-examples/
##
exitErr=(
    [124]="SIGTERM (Time out)"
    [133]="SIGTRAP (dividing an integer by zero)"
    [134]="SIGABRT (failed assertion)"
    [136]="SIGFPE (floating point exception or integer overflow)"
    [137]="SIGKILL"
    [139]="SIGSEGV (Segmentation fault)"
)

##
## Testing for MacOS
##
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ">>>>>>>>> Running the autograder on MacOS <<<<<<<<<<"
    if hash gsed 2>/dev/null; then
        SED=gsed
    else
        echo "Please install gnu-sed as follows:"
        echo "  brew install gnu-sed"
        exit 0
    fi
    if hash gawk 2>/dev/null; then
        AWK=gawk
    else
        echo "Please install gnu-awk as follows:"
        echo "  brew install gawk"
        exit 0
    fi
    if hash gwc 2>/dev/null; then
        WC=gwc
    else
        echo "Please install gnu-wc as follows:"
        echo "  brew install coreutils"
        exit 0
    fi
    if hash gtimeout 2>/dev/null; then
        TIMEOUT=gtimeout
    else
        echo "Please install gnu-timeout as follows:"
        echo "  brew install coreutils"
        exit 0
    fi
else
    SED=sed
    AWK=awk
    WC=wc
    TIMEOUT=timeout
fi

##
## Start autograding process
##
## $1: student dir
## $2: 1: rerun mode
## $3: if exist, specify the unit test number ==> single test mode
##
rerun=0
if [[ $# -ge 2 ]]; then
    rerun=$2
fi
cd $1
WHO=$1
if [[ $# -eq 3 ]]; then
    ## Single unit test mode
    gradeSingleStudent $3
else
    ## All unit tests mode
    gradeSingleStudent
fi
cd $TOP_DIR
