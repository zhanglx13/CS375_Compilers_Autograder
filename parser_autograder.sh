#! /bin/bash


TOP_DIR=$(pwd)
CS375DIR=~/Dropbox/CS375_Compilers
AUTOGRADERDIR=$CS375DIR/autograder
SUBDIR=$AUTOGRADERDIR/$1_gradingDir/*
SAMPLE=$AUTOGRADERDIR/trivb.sample


checkField()
{
    ##
    ## $1: input string
    ## $2: desired string
    ## $3: field name
    ## $4: symbol name
    ##
    ## checkField checks if $1 == $2 and
    ## output error message when necessary
    if [[ $1 != $2 ]]; then
        echo "Error: $3 of $4 should be $2, but input is $1"
    fi
}

checkVAR()
{
    ##
    ## $1 is the symbol table entry
    ## in the following format:
    ##
    ## 999929292 lim VAR    0 typ integer  lvl  1  siz     4  off     0
    ##
    ## $2 is the correct offset
    ##
    ## checkVAR checks each field of the entry using checkField

    ## Note that the following command can split space delimited string
    ## into an array
    symEntry=( $1 )
    echo "    Checking ${symEntry[1]}"
    ## SYMTYPE should be VAR
    checkField "${symEntry[2]}" "VAR" "symtype" "${symEntry[1]}"
    ## basicdt should be 0
    checkField "${symEntry[3]}" "0" "basicdt" "${symEntry[1]}"
    ## symtype should point to integer
    checkField "${symEntry[5]}" "integer" "symtype" "${symEntry[1]}"
    ## symbol table level should be 1
    checkField "${symEntry[7]}" "1" "symTable Level" "${symEntry[1]}"
    ## size of var should be 4
    checkField "${symEntry[9]}" "4" "size" "${symEntry[1]}"
    ## offset should be $2
    checkField "${symEntry[11]}" "$2" "offset" "${symEntry[1]}"
}

processResult()
{
    ##
    ## $1 is the result file to be processed
    ##

    ##
    ## Ignore everything before symbol table level 1
    ##
    sed -n "/Symbol table level 1/,//p" $1 > symtab_result
    ##
    ## Get the first and second symbol table entries
    ##
    firstSym=$(sed '2q;d' symtab_result)
    secondSym=$(sed '3q;d' symtab_result)
    ##
    ## Check the first and second entries
    ##
    echo "Checking symbol table"
    checkVAR "$firstSym" "0"
    checkVAR "$secondSym" "4"

    rm -f symtab_result
    ##
    ## Extract the parse tree
    ##
    sed -n "/(program graph1 (progn output)/,//p" $1 > tree_result
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
                ./parser < trivb.pas > result
                processResult result
            else
                echo "Compilation error, parser not found!"
            fi
        else
            echo "lexan.l not found!"
        fi
    elif [[ -f "parsc.c" ]]; then
        make parsec &> dump
        if [[ -f "parsec" ]]; then
            ./parsec < trivb.pas > result
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
