#! /bin/bash


TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
SUBDIR=$AUTOGRADERDIR/$1_gradingDir/*
SYMTABCHECKER=$AUTOGRADERDIR/symTable/bin/check_symtab
if [[ $1 == "p3" ]]; then
    INPUT=trivb.pas
    SAMPLE=$AUTOGRADERDIR/sample_trees/trivb.sample
    SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/trivb_table.txt
    ALIGN=$AUTOGRADERDIR/symTable/sample/align/trivb_align.txt
elif [[ $1 == "p4" ]]; then
    INPUT=graph1i.pas
    SAMPLE=$AUTOGRADERDIR/sample_trees/graph1i.sample
    SAMPLEST=$AUTOGRADERDIR/symTable/sample/table/graph1_table.txt
    ALIGN=$AUTOGRADERDIR/symTable/sample/align/graph1_align.txt
fi

processResult()
{
    ##
    ## $1 is the result file to be processed
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
    ##
    ## Extract the parse tree
    ##
    sed -n "/(program graph1/,//p" $1 > tree_result
    echo "Checking parsing tree"
    diff -w $SAMPLE tree_result

    rm -f tree_result
}

gradeSingleStudent()
{
    echo "############  $WHO  ###############"
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
cd symTable
make clean
make
cd $TOP_DIR
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
    echo "Usage: ./parser_autograder.sh px [studentDir]"
fi
