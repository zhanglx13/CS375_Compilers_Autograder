#! /usr/bin/env bash

## $1: file to be processed

#################################################################################
## Single line comment                                                         ## 
##                                                                             ##
## When gencode is commented on a single line, e.g.                            ##
##   // gencode(parseresult, blockoffs[blocknumber], labelnumber);             ##
##   /* gencode(parseresult, blockoffs[blocknumber], labelnumber); */          ##
## the single line sed command is used to replace the whole line with          ##
##   gencode(parseresult, blockoffs[blocknumber], labelnumber);                ##
##                                                                             ##
## sed                                                                         ##
## -i: modify the input file in place                                          ##
## s/patterna/patternb/: replace patterna with patterb for each line           ##
#################################################################################
sed  -i 's/\/\/ *gencode/gencode/' $1
sed  -i 's/\/\* *gencode.*\*\//gencode(parseresult, blockoffs[blocknumber], labelnumber);/' $1
#################################################################################
## Blank lines                                                                 ##
##                                                                             ##
## Before proceeding to multiple comment, remove blank lines in the main       ##
## function. Note that here we assume the lines in the main function is        ##
## less than 30                                                                ##
##                                                                             ##
## sed                                                                         ##
## /pattern/,//: match the line containing pattern till the end of file        ##
## {/pattern/action}: if a line matches/contains the pattern, take the action  ##
## ^$: regex denoting an empty line                                            ##
## d: delete the pattern                                                       ##
#################################################################################
sed  -i '/int main/,//{
     /^$/d
     }
' $1
#################################################################################
## Multi-line comments                                                         ##
##                                                                             ##
## Step 1: remove the /* before gencode                                        ##
##                                                                             ##
## sed                                                                         ##
## N: append the next line in the pattern space ==> the pattern space contains ##
##    two lines for matching. The newline can be matched using \n              ##
## P: print the first line in the pattern space                                ##
## D: delete the first line in the pattern space, and then go back to the      ##
##    first line of command. Now the pattern space contains the second line    ##
##    from the previous step.                                                  ##       
#################################################################################
sed -i '
    /\/\*/{
    N
    s/\/\* *\n* *gencode/gencode/
    P
    D
    }
' $1
#################################################################################
## Step 2: remove */ after gencode                                             ##
#################################################################################
sed -i '
    /gencode/{
    N
    s/\n* *\*\///
    P
    D
    }
' $1


