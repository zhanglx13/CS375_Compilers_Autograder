# Autograder for [CS375 Compilers](https://www.cs.utexas.edu/users/novak/cs375.html)

## Single Directory Grading

To grade a single student's submission, the autograder is invoked as follows

``` bash
./grade.sh -p n -d workingDir
```
where `n` is the project number starting from 1 and `workingDir` is the 
directory containing student's code.

This mode of autograding can also be used by students for testing.

## Batch Grading (For TA use only)

- Prepare students' code by `./scripts/prepare px`
- Compile the symbol table checker by `cd symTable; make`
- Run the corresponding autograder in batch mode
  - p1,p2: `./scripts/lexer_autograder.sh pn`
  - p3,p4,p5: `./scripts/parser_autograder.sh pn`
  - p6: It is not recommended to run batch mode for p6.


