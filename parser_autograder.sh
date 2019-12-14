#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##


TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
SYMTABCHECKER=$AUTOGRADERDIR/symTable/bin/check_symtab


checkSymbolTable()
{
    ##
    ## $1 the result file to be processed
    ##
    ## Other parameters are set as global variables:
    ##
    ## $SYMTABCHECKER: the executable of the c++ symbol table checker
    ## $SAMPLEST:      the sample symbol table
    ## $ALIGN:         the align file for the input
    ##
    ##
    ## Obtain the symbol table between
    ##   Symbol table level 1 
    ## and
    ##   yyparse result or (program graph1
    ##
    tac $1 | sed '/^Symbol table level 1/q' | tac  > clean_file
    if grep -Fxq "yyparse result =        0" clean_file
    then
        tac $1 | sed '/^Symbol table level 1/q' | tac | sed '/Symbol table level 1/,/yyparse result/!d;//d' > symtab_result
    else
        tac $1 | sed '/^Symbol table level 1/q' | tac | sed '/Symbol table level 1/,/(program graph1/!d;//d' > symtab_result
    fi
    ##
    ## Check the symbol table using the C++ checker
    ##
    echo "------------- Checking symbol table ----------"
    if [ -s symtab_result ]
    then
        $SYMTABCHECKER $SAMPLEST symtab_result $ALIGN > msg
        lines=$(cat msg | wc -l)
        if [ $lines == "0" ]
        then
            echo -e "\xE2\x9C\x94"
        else
            cat msg
        fi
    else
        echo "Empty Output. Maybe syntax error!!"
    fi
    rm -f symtab_result clean_file msg
}

processResult()
{
    echo ">>>>>>>>>>>>> Grading $INPUT >>>>>>>>>>>>>"
    ##
    ## $1 is the result file to be processed
    ##
    checkSymbolTable $1
    ##
    ## Extract the parse tree
    ##
    sed -n "/(program graph1/,//p" $1 > tree_result
    echo "------------- Checking parsing tree ----------"
    if [ -s tree_result ]
    then
        DIFF=$(diff -w $SAMPLE tree_result)
        if [ "$DIFF" != "" ]
        then
            diff -w $SAMPLE tree_result
        else
            echo -e "\xE2\x9C\x94"
        fi
    else
        echo "Empty Output. Maybe syntax error!!"
    fi

    rm -f tree_result
}

checkUnittest()
{
    ##
    ## $1 is the filename (w/out ext) of each unittest
    ##
    pass=0
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
            diff -w $SAMPLEDIR/$1.sample result
        else
            echo -e "\xE2\x9C\x94"
        fi
    else
        echo "Empty Output. Maybe syntax error or seg fault!!"
    fi
}

gradePasrec()
{
    ##
    ## $1 is the parser executable: parser or parsec
    ##
    echo ">>>>>>>>>>>>> Grading pasrec.pas >>>>>>>>>>>>>"
    SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/pasrec_table.txt
    ALIGN=$AUTOGRADERDIR/symTable/sample/align/pasrec_align.txt
    ##
    ## We set the executable as a global variable so that
    ## we do not need to pass it as one of the arguments
    ##
    PARSER=$1
    # test0: symbol table
    echo "@@@@@@@@@@ TEST 0 symbol table @@@@@@@@@@"
    $PARSER < $TESTDIR/test0_symtab.pas > test0_result
    if [ -s test0_result ]
    then
        checkSymbolTable test0_result
    else
        echo "Seg Fault!!"
    fi
    echo "@@@@@@@@@@ TEST 1 funcall new() @@@@@@@@@@"
    checkUnittest test1_newfun
    echo "@@@@@@@@@@ TEST 1_0 funcall new() @@@@@@@@@@"
    checkUnittest test1_newfun_0
    echo "@@@@@@@@@@ TEST 2 pointer and rec reference (simple) @@@@@@@@@@"
    checkUnittest test2_simpleRec
    echo "@@@@@@@@@@ TEST 2_0 pointer and rec reference (simple) @@@@@@@@@@"
    checkUnittest test2_simpleRec_0
    echo "@@@@@@@@@@ TEST 3 pointer and rec reference (hard) @@@@@@@@@@"
    checkUnittest test3_hardRec
    echo "@@@@@@@@@@ TEST 3_0 pointer and rec reference (hard) @@@@@@@@@@"
    checkUnittest test3_hardRec_0
    echo "@@@@@@@@@@ TEST 3_1 pointer and rec reference (hard) @@@@@@@@@@"
    checkUnittest test3_hardRec_1
    echo "@@@@@@@@@@ TEST 4 array access @@@@@@@@@@"
    checkUnittest test4_arr 4
    echo "@@@@@@@@@@ TEST 4_0 array access @@@@@@@@@@"
    checkUnittest test4_arr_0
    echo "@@@@@@@@@@ TEST 4_1 array access @@@@@@@@@@"
    checkUnittest test4_arr_1 4
    echo "@@@@@@@@@@ TEST 4_2 array access @@@@@@@@@@"
    checkUnittest test4_arr_2 4
    echo "@@@@@@@@@@ test5 while loop @@@@@@@@@@"
    checkUnittest test5_while 4
    echo "@@@@@@@@@@ test6 label/goto stmt @@@@@@@@@@"
    checkUnittest test6_label 4
    echo "@@@@@@@@@@ test7 write funcall @@@@@@@@@@"
    checkUnittest test7_write
}

gradeSingleStudent()
{
    echo "######################  $WHO  #########################"
    ##
    ## Compile student's code according to the submisions
    ##    
    if [[ -f "parse.y" ]]; then
        make parser &> dump
        if [[ -f "parser" ]]; then
            ./parser < $INPUT > result
            if [ -s result ]
            then 
                processResult result
            else
                echo "Seg Fault!!"
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
            ./parsec < $INPUT > result
            processResult result
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
                cd $student
                WHO=${student##*/}
                gradeSingleStudent
            done
        fi
    else
        echo "The first arg of ./parser_autograder.sh should only be p3, p4, or p5"
    fi
fi
