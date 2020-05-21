#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##


TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
SYMTABCHECKER=$AUTOGRADERDIR/symTable/bin/check_symtab

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
    strLen=$(echo ${#name})
    printf "\u250F"
    totalLen=$(echo "$strLen+$space+$space" | bc)
    repeatPrint "\u2501" $totalLen
    printf "\u2513\n"
    printf "\u2503"
    repeatPrint " " $space
    printf "%s" $WHO
    repeatPrint " " $space
    printf "\u2503\n"
    printf "\u2517"
    repeatPrint "\u2501" $totalLen
    printf "\u251B\n"
}

printTest()
{
    # $1 test to print
    # $2 the message to print on the same line of the test name
    space=2
    name="$1"
    strLen=$(echo ${#name})
    printf "\u2554"
    totalLen=$(echo "$strLen+$space+$space" | bc)
    repeatPrint "\u2550" $totalLen
    printf "\u2557\n"
    printf "\u2551"
    repeatPrint " " $space
    printf "%s" "$name"
    repeatPrint " " $space
    printf "\u2551  $2\n"
    printf "\u255A"
    repeatPrint "\u2550" $totalLen
    printf "\u255D\n"
}


checkSymbolTable()
{
    ##
    ## $1 the result file to be processed
    ##
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
    sed -n '/Symbol table level 1/,/(program graph1/{/^ *\([0-9]\+\|(\)/p}' $1 | sed '$d' > symtab_result
    ##
    ## Check the symbol table using the C++ checker
    ##
    if [ -s symtab_result ]
    then
        if [[ $# -eq 1 ]]; then
            $SYMTABCHECKER $SAMPLEST symtab_result $ALIGN > msg
        else
            $SYMTABCHECKER $2 symtab_result $3 > msg
        fi
        lines=$(cat msg | wc -l)
        if [ $lines == "0" ]
        then
            printf "\u2714\n"
        else
            lenMsg=$(wc -L msg | awk '{print $1}')
            printf "\n"
            cat msg
            repeatPrint "\u2501" $lenMsg
            printf "\n"
        fi
    else
        printf "Symbol table not found!!\n"
    fi
    rm -f symtab_result msg
}

##
## This script grades parser output from p3 and p4
##
## $1 parser output file
##
processResult()
{
    printTest $INPUT
    printf "\u25b6 Check symbol table:  "
    checkSymbolTable $1
    syntaxErr=$(grep "syntax error" $1)
    if [[ $syntaxErr ]]; then
        echo "  Found syntax error!!"
    else
        ##
        ## Extract the parse tree
        ##
        sed -n "/(program graph1/,//p" $1 > tree_result
        printf "\u25b6 Check parsing tree:  "
        if [ -s tree_result ]
        then
            DIFF=$(diff -w $SAMPLE tree_result)
            if [ "$DIFF" != "" ]
            then
                printf "\n"
                diff -w $SAMPLE tree_result
            else
                printf "\u2714\n"
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
        syntaxErr=$(grep "syntax error" tmp_err)
        if [[ $syntaxErr ]]; then
            ##
            ## Seg fault caused by syntax error
            ##
            printf "syntax error \u21D2 seg fault!!\n"
        else
            ##
            ## Seg fault caused by something else
            ## Probably an uninitialized basicdt of a token
            ## 
            printf "seg fault!!\n"
        fi
    else
        ##
        ## If no seg fault, check empty output
        ##
        $PARSER < $TESTDIR/$1.pas | sed -n "/(program/,//p" > result
        if [ -s result ]
        then
            DIFF=$(diff -w $SAMPLEDIR/$1.sample result)
            if [ "$DIFF" != "" ]
            then
                pass=0
            else
                pass=1
            fi
            ##
            ## When the second argument is provided
            ## $2 is the number of possible samples that
            ## can be matched
            ##
            ## The logic is that we test the next sample
            ## only when none of the previous samples are
            ## passed
            ##
            if [[ $# -eq 2 ]]; then
                START=0
                i=$2
                ((END=i-1))
                for (( c=$START; c<$END; c++ ))
                do
                    if [[ $pass == 0 ]]; then
                        temDIFF=$(diff -w $SAMPLEDIR/$1$c.sample result)
                        if [ "$temDIFF" == "" ]
                        then
                            pass=1
                        fi
                    fi
                done
            fi
            if [ $pass == 0 ]
            then
                diff -w $SAMPLEDIR/$1.sample result > msg
                ##
                ## Get the longest line length
                ##
                lenMsg=$(wc -L msg | awk '{print $1}')
                ##
                ## tmp_diffN contains d and c diff line numbers only
                ## tmp_sampleN contains the line numbers before d/c
                ##
                sed -n '/[[:digit:]][dc][[:digit:]]/p' msg > tmp_diffN
                awk 'BEGIN {FS="[dc]"}{print $1}' tmp_diffN > tmp_sampleN
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
                sL=$(wc -l $SAMPLEDIR/$1.sample | awk '{print $1}')
                printf "$diffL / $sL\n"
                cat msg
                repeatPrint "\u2501" $lenMsg
                printf "\n"
            else
                printf "\u2714\n"
            fi
        else
            printf "\n  Empty Output!!\n"
        fi
    fi
    rm -f result tmp_*
}

gradePasrec()
{
    ##
    ## $1 is the parser executable: parser or parsec
    ##
    printTest "pasrec.pas"
    SAMPLEST_PASREC=$AUTOGRADERDIR/symTable/sample/table/pasrec_table.txt
    ALIGN_PASREC=$AUTOGRADERDIR/symTable/sample/align/pasrec_align.txt
    ##
    ## We set the executable as a global variable so that
    ## we do not need to pass it as one of the arguments
    ##
    PARSER=$1
    # test0: symbol table
    printf "\u25b6 TEST 00:  "
    Msg=$($PARSER < $TESTDIR/test00_symtab.pas &> test0_result)
    if [[ $? -eq 139 ]];then
        syntaxErr=$(grep "syntax error" test0_result)
        if [[ $syntaxErr ]]; then
            ## seg fault caused by syntax error
            printf "syntax error \u21D2 seg fault!!\n"
        else
            printf "seg fault!!\n"
        fi
    else
        $PARSER < $TESTDIR/test00_symtab.pas > test0_result
        checkSymbolTable test0_result $SAMPLEST_PASREC $ALIGN_PASREC
        syntaxErr=$(grep "syntax error" test0_result)
        if [[ $syntaxErr ]]; then
            echo "  Found syntax error after symbol table!!"
        fi
    fi
    rm -f test0_result
    printf "\u25b6 TEST 01:  "
    checkUnittest test01_newfun
    printf "\u25b6 TEST 02:  "
    checkUnittest test02_newfun
    printf "\u25b6 TEST 03:  "
    checkUnittest test03_simpleRec
    printf "\u25b6 TEST 04:  "
    checkUnittest test04_simpleRec
    printf "\u25b6 TEST 05:  "
    checkUnittest test05_hardRec
    printf "\u25b6 TEST 06:  "
    checkUnittest test06_hardRec
    printf "\u25b6 TEST 07:  "
    checkUnittest test07_hardRec
    printf "\u25b6 TEST 08:  "
    checkUnittest test08_arr
    printf "\u25b6 TEST 09:  "
    checkUnittest test09_arr
    printf "\u25b6 TEST 10:  "
    checkUnittest test10_arr
    printf "\u25b6 TEST 11:  "
    checkUnittest test11_arr
    printf "\u25b6 TEST 12:  "
    ##
    ## Multiple samples due to label numbers
    ##
    checkUnittest test12_while 2
    printf "\u25b6 TEST 13:  "
    ##
    ## Multiple samples due to label numbers
    ##
    checkUnittest test13_label 2
    printf "\u25b6 TEST 14:  "
    checkUnittest test14_write
}

gradeSingleStudent()
{
    ##
    ## Compile student's code according to the submisions
    ##    
    if [[ -f "parse.y" ]]; then
        ## disable parser-tracing function
        sed -i "s/yydebug/\/\/yydebug/g" parse.y
        make parser &> dump
        if [[ -f "parser" ]]; then
            Msg=$(./parser < $INPUT)
            if [[ $? -eq 139 ]];then
                printTest $INPUT "Seg fault!!"
            else
                ./parser < $INPUT &> result
                processResult result
            fi

            if [[ $LEVEL == 2 ]]; then
                gradePasrec ./parser
            fi
        else
            echo "Compilation error, parser not found!"
        fi
    elif [[ -f "parsc.c" ]]; then
        make parsec &> dump
        if [[ -f "parsec" ]]; then
            Msg=$(./parsec < $INPUT)
            if [[ $? -eq 139 ]]; then
                echo "Seg Fault!!"
            else
                ./parsec < $INPUT &> result
                processResult result
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
            SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/trivb_table.txt
            ALIGN=$AUTOGRADERDIR/symTable/sample/align/trivb_align.txt
        elif [[ $1 == "p4" ]]; then
            LEVEL=1
            INPUT=graph1i.pas
            SAMPLE=$AUTOGRADERDIR/sample_trees/graph1i.sample
            SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/graph1_table.txt
            ALIGN=$AUTOGRADERDIR/symTable/sample/align/graph1_align.txt
        elif [[ $1 == "p5" ]]; then
            LEVEL=2
            INPUT=graph1i.pas
            SAMPLE=$AUTOGRADERDIR/sample_trees/graph1i.sample
            SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/graph1_table.txt
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
