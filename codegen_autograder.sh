#!/usr/bin/env bash

##
## To use associative array declaration, must use bash version
## >= 4. The above line makes sure to always use the newest bash
##

###########################################################################
##                                                                       ##
## Autograder for project 6 --- codegen,c                                ##
##                                                                       ##
## The autograder can be used for grading all students' code             ##
## (all mode) or a single student's code (single mode)                   ##
## according to the first argument                                       ##
##                                                                       ## 
## Usage: ./codegen_autograder.sh p6|studentDir                          ##
##                                                                       ##
## gradeSingleStudent                                                    ##
##                                                                       ##
##   Both all mode and single mode will call gradeSingleStudent,         ##
##   in which one student's code is compiled according to the            ##
##   files submitted. Then the executable will be passed as              ##
##   the only argument to gradeCodegen.                                  ##
##                                                                       ##
##   Arg:                                                                ##
##     No input. gradeSingleStudent is called after cd'ing into          ##
##     the student's folder                                              ##
##                                                                       ##
##   Compilation mode:                                                   ##
##     1. If parse.y is found, then compile using make compiler          ##
##     2. If parsc.c is found, then compile using make compc             ##
##                                                                       ##
## gradeCodegen                                                          ##
##                                                                       ##
##   Simply call gradeUnittest for both graph1 and pasrec                ##
##                                                                       ##
##   Arg:                                                                ##
##     $1: compiler executable                                           ##
##                                                                       ##
## gradeUnittest                                                         ##
##                                                                       ##
##   Run the compiler executable on each of the unit test in             ##
##   the test folder and compare the result with the                     ##
##   corresponding sample in the sample folder                           ##
##                                                                       ##
##   Args:                                                               ##
##     $1: compiler executable                                           ##
##     $2: test folder full path name                                    ##
##     $3: sample folder full path name                                  ##
##                                                                       ##
##   How to compare for each unit test                                   ##
##     1. [Seg Fault?] Run the compiler executable on the test           ##
##        and redirect the result into a temp file. If $? equals         ##
##        139, then a seg fault signal is received.                      ##
##     2. [No code generated?] Check if there is nothing between         ##
##        /begin Your code/ and /begin Epilogue code/. If so             ##
##        print out "No Code generated!!". This is helped with           ##
##        countLines.                                                    ##
##     3. [first diff] diff sample output after removing all             ##
##        comments in both sample and output. If diff outputs            ##
##        nothing, print out "\xE2\x9C\x94" which is the check           ##
##        mark.                                                          ##
##     4. [second diff] if the output and the sample does not            ##
##        match for the first time, the output has a second              ##
##        chance to match another sample if it exists. The               ##
##        second sample for the same test has a name same as             ##
##        the first sample appended a 0 to the basename of               ##
##        the filename.                                                  ##
##        E.g.                                                           ##
##        For test25.pas, the first sample is named as                   ##
##        test25.sample and the second sample is named as                ##
##        test250.sample.                                                ##
##        Since we always use two digits to represent a test             ##
##        number, e.g. test03.pas instead of test3.pas, the              ##
##        second sample (e.g. test030.sample) will not be                ##
##        confused with any first samples (e.g. test30.sample).          ##
##     5. [Not Match] When the output does not match any of              ##
##        the samples, we print the following two things                 ##
##        a. diff result between sample and output with                  ##
##           comment removed                                             ##
##        b. code between /begin Your code/ and /begin Epilogue code/    ##
##           in the sample                                               ##
##                                                                       ##
##                                                                       ##
## TODO:                                                                 ##
##   1. The output when result does not match can still be               ##
##      hard for grading, especially when student has a lot              ##
##      of small issues. Sometimes I feel like printing the              ##
##      whole student's output also. But this adds info                  ##
##      when student's code does match well. Maybe a heuristic           ##
##      can be used:                                                     ##
##      when the number of diff exceeds a threshold, print               ##
##      student's output also                                            ##
##                                                                       ##
###########################################################################
TOP_DIR=$(pwd)
AUTOGRADERDIR=$TOP_DIR
TEST_DIR=$AUTOGRADERDIR/test_p6
SAMPLE_DIR=$AUTOGRADERDIR/sample_p6


countAsmLines()
{
    ##
    ## $1 is the output file
    ##
    sed -n '/begin Your code/,/begin Epilogue code/p' $1 | wc -l
}

gradeUnittest()
{
    ##
    ## $1 executable file name
    ## $2 folder (full path) containing tests
    ## $3 folder (full path) containing samples
    ##
    zero=0
    pass=0
    for entry in $2/*
    do
        testN=$(basename "$entry")
        testN="${testN%.*}"
        echo "@@@@@@@@@@@@@@@@@@@@ testing $testN: @@@@@@@@@@@@@@@@@@@"
        Msg=$($1 < $entry &> tmp_err)
        ##
        ## Check seg fault 
        ##
        if [[ $? -eq 139 ]];then
            syntaxErr=$(grep "syntax error" tmp_err)
            if [[ $syntaxErr ]]; then
                echo "syntax error ==> seg fault!!"
            else
                echo "Seg Fault!!"
            fi
            pass=2
        else
            ##
            ## If no seg fault, get assembly code
            ##
            ## Note that we do not need to check syntax error here.
            ## The rationale is that when syntax error happens in the parsing
            ## phase, there will always be a seg fault when gencode is called.
            ## Therefore, the syntax error was caught in the previous case.
            ##
            $1 < $entry | sed -n "/begin Your code/,//p" > tmp_result
            ##
            ## Check empty output
            ##
            if [ -s tmp_result ]
            then
                ##
                ## First we check if the output is empty between the markers
                ##
                nL=$(countAsmLines tmp_result)
                if [ $nL == "2" ]
                then
                    echo "No Assembly Code Generated!!"
                    pass=2
                else
                    ##
                    ## When diffing, we want to ignore comments
                    ##
                    sed '/^[[:blank:]]*#/d;s/#.*//' tmp_result > output
                    sed '/^[[:blank:]]*#/d;s/#.*//' $3/"$testN.sample" > sample
                    DIFF=$(diff -w sample output)
                    if [ "$DIFF" != "" ]
                    then
                        ##
                        ## If the output does not match the sample
                        ## Try to see if there is an alternative sample
                        ##
                        if [ -f $3/$testN$zero.sample ]; then
                            sed '/^[[:blank:]]*#/d;s/#.*//' $3/$testN$zero.sample > sample
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
            else
                ##
                ## Empty output usually means gencode is commented out in the
                ## main(). Here we try to uncomment gencode in parse.y and
                ## rerun the autograder.
                ## 
                echo "Empty Output ==> gencode might be commented out!!"
                if [[ "$1" == "./compiler" ]]; then
                    echo "  ... backup parse.y ==> parse_orig.y ..."
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
                    sed -n -i '1{h;d}; H;$!d; x ; s|/\*[^a-zA-Z]*\(gencode.*;\)[\n ]*\*/|\1|;p' parse.y
                    #########################################################################
                    ## Step 2: Remove // before gencode() at the same line                 ## 
                    ##                                                                     ##
                    ## sed commands                                                        ##
                    ## 1. This only works for the gencode() line.                          ##
                    ## 2. This command removes anything between // and gencode             ##
                    ## 3. This command removes anything after gencode();                   ##
                    #########################################################################
                    sed -i 's|^\([ ]*\)//.*\(gencode.*;\).*|\1\2|' parse.y
                    echo "  ... rerun the autograder ..."
                    CURDIR=$(pwd)
                    cd $AUTOGRADERDIR
                    ./codegen_autograder.sh $CURDIR
                else
                    echo "  ... parsc.c needs to be fixed ..."
                    echo "  ... please fix it manually ..."
                fi
                ##
                ## terminate the autograder when re-run completes
                ## 
                exit 0
            fi
        fi

        if [ $pass == 0 ]
        then
            ##
            ## Count the diff lines and generate a simple report
            ## at the end
            ##
            ##
            ## Count the assembly code lines in the sample
            ##
            sL=$(countAsmLines $3/"$testN.sample")
            sL=$(echo "$sL-2" | bc)
            ##
            ## Output diff
            ##
            echo ">>>>>>>> DIFF <<<<<<<<"
            diff -w sample output | tee tmp_diff
            ##
            ## tmp_diffN contains d and c diff line numbers only
            ## tmp_sampleN contains the line numbers before d/c
            ##
            sed -n '/[[:digit:]][dc][[:digit:]]/p' tmp_diff > tmp_diffN
            awk 'BEGIN {FS="[dc]"}{print $1}' tmp_diffN > tmp_sampleN
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
            ##
            ## Output sample
            ##
            echo ">>>>>>>> Sample <<<<<<<<"
            ##
            ## When they are different, we might want to check the
            ## sample. But only the important section of the sample
            ##
            sed -n '/begin Your code/,/begin Epilogue code/p' $3/"$testN.sample" |
                sed '1d;$d' |
                awk '{print NR ":" $0}'
            ##
            ## Output a report
            ## 
            echo ">>>>>>>> Report <<<<<<<<"
            echo "wrong assembly code lines: $diffL / $sL"
            if [[ $epilogue -eq 1 ]]; then
                echo "something wrong in epilogue"
            fi
        elif [ $pass == 1 ]
        then
            ##
            ## When PASS, print out the check mark
            ##
            echo -e "\xE2\x9C\x94"
        fi
    done
    rm -f tmp_* output sample
}


gradeSingleStudent()
{
    echo "######################  $WHO  #########################"

    if [[ -f "parse.y" ]]; then
        ## disable parser-tracing function
        sed -i 's/yydebug/\/\/yydebug/g' parse.y
        ## Canonicalize the parse tree before calling gencode
        sed -i 's/gencode/exprCanonicalization(parseresult);gencode/g' parse.y
        make compiler &> dump
        ## Reverse source code modification after compilation
        sed -i 's/exprCanonicalization(parseresult);gencode/gencode/g' parse.y
        sed -i 's/\/\/yydebug/yydebug/g' parse.y
        if [[ -f "compiler" ]]; then
            gradeUnittest ./compiler $TEST_DIR $SAMPLE_DIR
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
    
    rm -f result dump
}



##
## Start autograding process
##
if [[ $# -eq 1 ]];
then
    if [ $1 == "p6" ];
    then
        ##
        ## $1 is one of project number
        ## invoke the all mode
        ##
        SUBDIR=~/CS375_gradingDir/*
        for student in $SUBDIR
        do
            cd $student
            WHO=${student##*/}
            gradeSingleStudent
            cd $TOP_DIR
        done
    else
        ##
        ## $1 is the student dir
        ## invoke the single mode
        ##
        cd $1
        WHO=$1
        gradeSingleStudent
        cd $TOP_DIR
    fi
else
    echo "Usage: ./codegen_autograder.sh p6|studentDir"
fi
