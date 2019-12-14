# Instructions for autograding

## Project 1 Lexical Analyzer

1. Make sure students submit the right files. Unzip any zipped files.
2. run `./prepare.sh p1`
   Note that prepare.sh also does the unzipping and renaming.
3. run `./lexer_autograder.sh p1` for all students
4. run `./lexer_autograder.sh p1 studentDir` for a single student

## Project 2 Lexer

Same as project 1 except p1 should be replaced with p2.

## Project 3 Parsing trivb.pas

1. `./prepare.sh p3`
2. `./parser_autograder.sh p3` to grade all students.
3. Or `./parser_autograder.sh p3 studentDir` to grade a single student.

## Project 4 Parsing graph1.pas (graph1i.pas)

Same as project 3 except p3 should be replaced with p4.

Note that the c++ symbol table checker is in the symTable dir.
For portability issues, the autograder will NOT compile the checker automatically.
Therefore, before running the autograder, do make clean && make in the symTable dir.

## Project 5 Parsing pasrec.pas and graph1i.pas

Same as project 3 except p3 should be replaced with p5

## Project 6 Code generation for graph1.pas and pasrec.pas

Same as the above projects except that the autograder is now codegen_autograder.sh and the project dir is always p6.

# File Structures

## Autograder scripts

1. lexer_autograder.sh: autograder for project 1, 2
2. parser_autograder.sh: autograder for project 3,4,5
3. codegen_autograder.sh: autograder for project 6

## tests and samples

1. test_p1: each test (scantst_n.pas) corresponds to line n in scantst.pas excluding empty lines. This folder is used as the input tests for project 1 and 2
2. sample_p1: sample output for each test in test_p1 using lexer. This is used as the sample for project 1
3. sample_p2: sample output for each test in test_p1 using lex. This is used as the sample for project 2
4. test_p5: unit tests extracted from pasrec.pasrec
5. sample_p5: samples for each test in test_p5. Note that if one test has multiple samples, the alternative samples should have the same name as the test with a number appended.
   E.g. test4_arr.pas can have multiple samples: test4_arr.sample, test4_arr0.sample, test4_arr1.sample, etc.
   test4_arr_1.pas can have multiple samples: test4_arr_1.sample, test4_arr_10.sample, test4_arr_11.sample, etc
6. graph1_test, graph1_sample, pasrec_test, pasrec_sample: unit tests and samples for the codegen project. Similary, multiple samples for the same test are distinguished by the appended number to the sample name.
7. sample_trees: contains trivb.sample and graph1i.sample. These outputs are generated using the modified pprint.c, therefore, the layout and indentation of the output is different.

## Symbol Table Checker

1. symTable: C++ code to check the correctness of the symbol table

## Utility scripts and files

1. ./prepare.sh: Used to move students' code into ~/CS375_gradingDir
2. ./copy.sh: used by ./prepare.sh to copy useful files from cs375_minimal into student's folder
3. cs375_minimal: contains all other files that are necessary to build each project. Changes are made to makefile, pprint.c, and printtoken.c
4. ./check_moss.sh: copy all students' code into a folder and use moss.sh to check plagiarism
5. ./toServer.sh: copy a file or a folder to lxzhang@linux.cs.utexas.edu:/u/lxzhang/CS375_auto/

## Experiment on compiler issues

1. compiler_issue
