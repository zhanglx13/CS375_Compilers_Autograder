#! /bin/bash


TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
SUBDIR=$AUTOGRADERDIR/$1_gradingDir/*
SYMTABCHECKER=$AUTOGRADERDIR/symTable/bin/check_symtab
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
    ##   yyparse result
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
    echo "Checking symbol table"
    $SYMTABCHECKER $SAMPLEST symtab_result $ALIGN
    rm -f symtab_result clean_file
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
    echo "Checking parsing tree"
    diff -w $SAMPLE tree_result

    rm -f tree_result
}

checkUnittest()
{
    ##
    ## $1 is the filename (w/out ext) of each unittest
    ##
    pass=0
    $PARSER < $TESTDIR/$1.pas | sed -n "/(program/,//p" > result
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
        echo "PASS!"
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
    echo "@@@ TEST 0 symbol table @@@"
    $PARSER < $TESTDIR/test0_symtab.pas > test0_result
    checkSymbolTable test0_result
    echo "@@@ TEST 1 funcall new() @@@"
    checkUnittest test1_newfun
    echo "@@@ TEST 1_0 funcall new() @@@"
    checkUnittest test1_newfun_0
    echo "@@@ TEST 2 pointer and rec reference (simple) @@@"
    checkUnittest test2_simpleRec
    echo "@@@ TEST 2_0 pointer and rec reference (simple) @@@"
    checkUnittest test2_simpleRec_0
    echo "@@@ TEST 3 pointer and rec reference (hard) @@@"
    checkUnittest test3_hardRec
    echo "@@@ TEST 3_0 pointer and rec reference (hard) @@@"
    checkUnittest test3_hardRec_0
    echo "@@@ TEST 3_1 pointer and rec reference (hard) @@@"
    checkUnittest test3_hardRec_1
    echo "@@@ TEST 4 array access @@@"
    checkUnittest test4_arr 4
    echo "@@@ TEST 4_0 array access @@@"
    checkUnittest test4_arr_0
    echo "@@@ TEST 4_1 array access @@@"
    checkUnittest test4_arr_1 4
    echo "@@@ TEST 4_2 array access @@@"
    checkUnittest test4_arr_2 4
    echo "@@@ test5 while loop @@@"
    checkUnittest test5_while 4
    echo "@@@ test6 label/goto stmt @@@"
    checkUnittest test6_label 4
    echo "@@@ test7 write funcall @@@"
    checkUnittest test7_write
}

gradeSingleStudent()
{
    echo "######################  $WHO  #########################"
    ##
    ## Compile student's code according to the submisions
    ##
    ## Then run the parser/parsec on trivb.pas
    ## Direct the result into a file to be processed
    
    if [[ -f "parse.y" ]]; then
        if [[ -f "lexan.l" ]]; then
            make parser &> dump
            if [[ -f "parser" ]]; then
                ./parser < $INPUT > result
                processResult result
                if [[ $LEVEL == 2 ]]; then
                    gradePasrec ./parser
                fi
            else
                echo "Compilation error, parser not found!"
            fi
        else
            echo "lexan.l not found! Copying from p2 ... "
            cp $AUTOGRADERDIR/p2_gradingDir/$WHO/lexan.l ./
            gradeSingleStudent
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
##
## Run tests for one student
##
if [[ $# -eq 2 ]]; then
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
    echo "Usage: ./parser_autograder.sh px [studentDir]"
fi
