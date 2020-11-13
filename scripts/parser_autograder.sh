#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##


TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
SYMTABCHECKER=$AUTOGRADERDIR/symTable/bin/check_symtab

source $AUTOGRADERDIR/scripts/checksym.sh

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


checkSymbolTable()
{
    ##
    ## $1: the result file to be processed
    ## $2: filename for target symbol table output
    ##
    ## Extract anything between "Symbol table level 1"
    ## and "(program graph1" that starts with either a digit or '('
    $SED -n '/Symbol table level 1/,/(program graph1/{/^ *\([0-9]\+\|(\)/p}' $1 > symtab_result.tmp
    ## Check if the parse tree is printed
    if $GREP -q "(program graph1" symtab_result.tmp
    then
        ## If so, remove the (program graph1 line
        $SED -i '$d' symtab_result.tmp
    else
        ## If not, print a warning message
        echo "Warning: the parse tree is not found!!"
        ##
        ## What if only the first line of the parse tree is not printed?
        ##
    fi

    if [ -s symtab_result.tmp ]
    then
        output=symtab_result.tmp
        target=$2
        pass=1
        compareCONST > err_msg.tmp
        processTYPE >> err_msg.tmp
        processVAR >> err_msg.tmp

        if [[ $pass -eq 1 ]];then
            printf "All Good!!\n"
        else
            lenMsg=$($WC -L err_msg.tmp | $AWK '{print $1}')
            printf "\n"
            cat err_msg.tmp
            repeatPrint "-" $lenMsg
            printf "\n"
        fi
    else
        printf "Symbol table not found!!\n"
    fi
    rm *.tmp

    ## Other parameters are set as global variables:
    ##
    ## $SYMTABCHECKER: the executable of the c++ symbol table checker
    ## $2:             the sample symbol table. If not specified, $SAMPLEST is used
    ## $3:             the align file for the input. If not specified, $ALIGN is used
    ##
    ##
    ## Obtain the symbol table between
    ##   Symbol table level 1 
    ## and
    ##   yyparse result or (program graph1 or token xxxxx OP program
    ##
    ## The following script is extracting anything between "Symbol table level 1"
    ## and "(program graph1" that starts with either a digit or '('
    #$SED -n '/Symbol table level 1/,/(program graph1/{/^ *\([0-9]\+\|(\)/p}' $1 | $SED '$d' > symtab_result
    ##
    ## Check the symbol table using the C++ checker
    ##
    # if [ -s symtab_result ]
    # then
    #     if [[ $# -eq 1 ]]; then
    #         $SYMTABCHECKER $SAMPLEST symtab_result $ALIGN > msg
    #     else
    #         $SYMTABCHECKER $2 symtab_result $3 > msg
    #     fi
    #     lines=$(cat msg | wc -l)
    #     if [ $lines == "0" ]
    #     then
    #         printf "All Good!!\n"
    #     else
    #         lenMsg=$(wc -L msg | $AWK '{print $1}')
    #         printf "\n"
    #         cat msg
    #         repeatPrint "-" $lenMsg
    #         printf "\n"
    #     fi
    # else
    #     printf "Symbol table not found!!\n"
    # fi
    # rm -f symtab_result msg
}

##
## This script grades parser output from p3 and p4
##
## $1: parser output file
## $2: sample symbol table output
##
processResult()
{
    printTest $INPUT
    printf "> Check symbol table:  "
    checkSymbolTable $1 $2
    syntaxErr=$($GREP "syntax error" $1)
    if [[ $syntaxErr ]]; then
        echo "  Found syntax error!!"
    else
        ##
        ## Extract the parse tree
        ##
        $SED -n "/(program graph1/,//p" $1 > tree_result
        printf "> Check parsing tree:  "
        if [ -s tree_result ]
        then
            DIFF=$(diff -w $SAMPLE tree_result)
            if [ "$DIFF" != "" ]
            then
                printf "\n"
                diff -w $SAMPLE tree_result
            else
                printf "All Good!!\n"
            fi
        else
            printf "Output tree not found!!\n"
        fi
    fi
    rm -f tree_result
}

checkUnittest()
{
    ##
    ## $1 is the filename (w/out ext) of each unittest
    ##
    pass=0
    Msg=$($PARSER < $TESTDIR/$1.pas &> tmp_err)
    ##
    ## Check seg fault 
    ##
    if [[ $? -eq 139 ]];then
        syntaxErr=$($GREP "syntax error" tmp_err)
        if [[ $syntaxErr ]]; then
            ##
            ## Seg fault caused by syntax error
            ##
            echo "syntax error ==> seg fault!!"
        else
            ##
            ## Seg fault caused by something else
            ## Probably an uninitialized basicdt of a token
            ## 
            echo "seg fault!!"
        fi
    else
        ##
        ## If no seg fault, check empty output
        ##
        $PARSER < $TESTDIR/$1.pas | $SED -n "/(program/,//p" > result
        if [ -s result ]
        then
            DIFF=$(diff -w $SAMPLEDIR/$1.sample result)
            if [ "$DIFF" != "" ]
            then
                pass=0
            else
                pass=1
            fi
            ##################################################################
            ## This method is not used now
            ##
            ## When the second argument is provided
            ## $2 is the number of possible samples that
            ## can be matched
            ##
            ## The logic is that we test the next sample
            ## only when none of the previous samples are
            ## passed
            ##
            #if [[ $# -eq 2 ]]; then
            #    START=0
            #    i=$2
            #    ((END=i-1))
            #    for (( c=$START; c<$END; c++ ))
            #    do
            #        if [[ $pass == 0 ]]; then
            #            temDIFF=$(diff -w $SAMPLEDIR/$1$c.sample result)
            #            if [ "$temDIFF" == "" ]
            #            then
            #                pass=1
            #            fi
            #        fi
            #    done
            #fi
            #################################################################

            #################################################################
            ## When DIFF is not empty and there is another sample for this ##
            ## test, we do another check.                                  ##
            ## For now, only one more check is needed.                     ##
            #################################################################
            if [[ $pass -eq 0 ]] && [[ -f $SAMPLEDIR/$1"0".sample ]]; then
                fext="0.sample"
                tmpDIFF=$(diff -w $SAMPLEDIR/$1$fext result)
                if [ "$tmpDIFF" == "" ]
                then
                    pass=1
                fi
            fi
            ##
            ## Output according to pass or not
            ##
            if [ $pass == 0 ]
            then
                diff -w $SAMPLEDIR/$1.sample result > msg
                ##
                ## Get the longest line length
                ##
                lenMsg=$($WC -L msg | $AWK '{print $1}')
                ##
                ## tmp_diffN contains d and c diff line numbers only
                ## tmp_sampleN contains the line numbers before d/c
                ##
                $SED -n '/[[:digit:]][dc][[:digit:]]/p' msg > tmp_diffN
                $AWK 'BEGIN {FS="[dc]"}{print $1}' tmp_diffN > tmp_sampleN
                diffL=0
                while read -r line
                do
                    ##
                    ## $beforeN stores the starting line number
                    ## $afterN stores the end line number
                    ##
                    beforeN=${line/,[0-9]*/}
                    afterN=${line/[0-9]*,/}
                    diffL=$(echo "$diffL+$afterN-$beforeN+1" | bc)
                done < tmp_sampleN
                sL=$($WC -l $SAMPLEDIR/$1.sample | $AWK '{print $1}')
                ##
                ## The first two lines will always be
                ## (program graph1
                ## (progn output)
                ## and it is assumed these two line do not have diffs.
                ##
                sL=$(echo "$sL-2" | bc)
                printf "$diffL / $sL\n"
                cat msg
                repeatPrint "-" $lenMsg
                printf "\n"
            else
                printf "All Good!!\n"
            fi
        else
            printf "empty output!!\n"
        fi
    fi
    rm -f result tmp_* msg
}

gradePasrec()
{
    ##
    ## $1 is the parser executable: parser or parsec
    ##
    printTest "pasrec.pas"
    #SAMPLEST_PASREC=$AUTOGRADERDIR/symTable/sample/table/pasrec_table.txt
    #ALIGN_PASREC=$AUTOGRADERDIR/symTable/sample/align/pasrec_align.txt
    ##
    ## We set the executable as a global variable so that
    ## we do not need to pass it as one of the arguments
    ##
    PARSER=$1
    for testNFullName in $TESTDIR/*
    do
        ## Remove path and extension
        testN=${testNFullName##*/}
        testN=${testN%.*}
        testNo=${testN##test}
        printf "> TEST $testNo (${points[$testNo]}):  "
        if [[ ${symbolTest[$testNo]} ]];
        then
            ##
            ## Check symbol table
            ##
            Msg=$($PARSER < $TESTDIR/$testN.pas &> output.tmp)
            if [[ $? -eq 139 ]];then
                syntaxErr=$($GREP "syntax error" output.tmp)
                if [[ $syntaxErr ]]; then
                    ## seg fault caused by syntax error
                    echo "syntax error ==> seg fault!!"
                else
                    echo "seg fault!!"
                fi
            else
                checkSymbolTable output.tmp $SAMPLEDIR/$testN.sample
            fi
        else
            ##
            ## Check other unit tests
            ##
            checkUnittest $testN
        fi
    done
}

gradeSingleStudent()
{
    ##
    ## Compile student's code according to the submissions
    ##
    if [[ -f "parse.y" ]]; then
        ## disable parser-tracing function
        $SED -i "s/yydebug/\/\/yydebug/g" parse.y
        ##
        ## Dump the stdout to compilation_dump
        ## Dump the stderr to err_dump
        ##
        make parser > compilation_dump 2> err_dump
        ## Revoke the change to parse.y
        $SED -i "s/\/\/yydebug/yydebug/g" parse.y
        if [[ -f "parser" ]]; then
            Msg=$(./parser < $INPUT)
            if [[ $? -eq 139 ]];then
                printTest $INPUT "Seg fault!!"
            else
                ./parser < $INPUT &> result
                processResult result $SAMPLEST
            fi

            if [[ $LEVEL == 2 ]]; then
                gradePasrec ./parser
            fi
        else
            echo "Compilation error, parser not found!"
            echo "Stderr:"
            cat err_dump
        fi
    elif [[ -f "parsc.c" ]]; then
        make parsec &> dump
        if [[ -f "parsec" ]]; then
            Msg=$(./parsec < $INPUT)
            if [[ $? -eq 139 ]]; then
                echo "Seg Fault!!"
            else
                ./parsec < $INPUT &> result
                processResult result $SAMPLEST
            fi
            if [[ $LEVEL == 2 ]]; then
                gradePasrec ./parsec
            fi
        else
            echo "Compilation error, parsec not found!"
        fi
    else
        echo "Parser file (parse.y or parsc.c) not found!"
    fi

    rm -f result dump
}


##
## Start the autograder
##
## Compile the C++ symbol table checker
##
## Note that the checker only needs to be recompiled
## when it is changed or move between Linux and Mac
##
#cd symTable
#make clean
#make
#cd $TOP_DIR

declare -A pArray
pArray=(
    [p3]=1
    [p4]=1
    [p5]=1
)

declare -A points
points=(
    [00]=4
    [01]=5
    [02]=8
    [03]=8
    [04]=4
    [05]=4
    [06]=5
    [07]=5
    [08]=8
    [09]=6
    [10]=4
    [11]=4
    [12]=5
    [13]=6
    [14]=6
    [15]=8
)

declare -A symbolTest
## The first 4 test for p5 is for symbol tables
symbolTest=(
    [00]=1
    [01]=1
    [02]=1
    [03]=1
)

##
## Testing for MacOS
## Check for gnu version of timeout and egrep
##
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo ">>>>>>>>> Running the autograder on MacOS <<<<<<<<<<"
    ## Check for timeout
    # if hash gtimeout 2>/dev/null; then
    #     TIMEOUT=gtimeout
    # else
    #     echo "Please install gnu-timeout as follows:"
    #     echo "  brew install coreutils"
    #     exit 0
    # fi
    ## Check gnu-grep
    if hash ggrep 2>/dev/null; then
        GREP=ggrep
    else
        echo "Please install gnu-grep as follows:"
        echo "  brew install grep"
        exit 0
    fi
    ## Check gnu-sed
    if hash gsed 2>/dev/null; then
        SED=gsed
    else
        echo "Please install gnu-sed as follows:"
        echo "  brew install gnu-sed"
        exit 0
    fi
    ## Check for gnu-awk
    if hash gawk 2>/dev/null; then
        AWK=gawk
    else
        echo "Please install gnu-awk as follows:"
        echo "  brew install gawk"
        exit 0
    fi
    ## Check for gnu-wc
    if hash gwc 2>/dev/null; then
        WC=gwc
    else
        echo "Please install gnu-wc as follows:"
        echo "  brew install coreutils"
        exit 0
    fi
else
    # TIMEOUT=timeout
    GREP=grep
    SED=sed
    AWK=awk
    WC=wc
fi

if [[ $# -eq 0 ]] || [[ $# -gt 2 ]];
then
    echo "Must specify one or two args"
    echo "Usage: ./parser_autograder.sh px [studentDir]"
else
    ##
    ## First check if the first arg is p3,p4,or p5
    ##
    if [[ ${pArray[$1]} ]];
    then
        ##
        ## Set globals first
        ##
        if [[ $1 == "p3" ]]; then
            LEVEL=0
            INPUT=trivb.pas
            SAMPLE=$AUTOGRADERDIR/sample_trees/trivb.sample
            SAMPLEST=$AUTOGRADERDIR/sample_symtab/trivb_table.txt
            ALIGN=$AUTOGRADERDIR/symTable/sample/align/trivb_align.txt
        elif [[ $1 == "p4" ]]; then
            LEVEL=1
            INPUT=graph1i.pas
            SAMPLE=$AUTOGRADERDIR/sample_trees/graph1i.sample
            SAMPLEST=$AUTOGRADERDIR/sample_symtab/graph1_table.txt
            ALIGN=$AUTOGRADERDIR/symTable/sample/align/graph1_align.txt
        elif [[ $1 == "p5" ]]; then
            LEVEL=2
            INPUT=graph1i.pas
            SAMPLE=$AUTOGRADERDIR/sample_trees/graph1i.sample
            SAMPLEST=$AUTOGRADERDIR/sample_symtab/graph1_table.txt
            ALIGN=$AUTOGRADERDIR/symTable/sample/align/graph1_align.txt
            TESTDIR=$AUTOGRADERDIR/test_p5
            SAMPLEDIR=$AUTOGRADERDIR/sample_p5
        fi
        if [[ $# -eq 2 ]]; then
            ##
            ## single mode
            ##
            cd $2
            WHO=$2
            ##
            ## $WHO will be used to copy lexan.l if it is not
            ## found in the current folder
            ## Before processing, $WHO contains px_gradingDir
            ## The following line deletes everything until it
            ## matches the first '/'
            ##
            WHO=${WHO#*/}
            gradeSingleStudent
        else
            ##
            ## Run tests for all students in ~/CS375_gradingDir/
            ##
            SUBDIR=~/CS375_gradingDir/*
            for student in $SUBDIR
            do
                if [[ -d $student ]]; then
                    cd $student
                    WHO=${student##*/}
                    printName $WHO
                    gradeSingleStudent
                fi
            done
        fi
    else
        echo "The first arg of ./parser_autograder.sh should only be p3, p4, or p5"
    fi
fi
