# Rubrics for project 6 --- code generation for graph1i.pas and pasrec.pas

## Grading and Rubrics

**Your code will be checked for plagiarism against each other as well as some online 
github code using moss. 
If you get caught, you will get a 0 for this project.**

1. `graph1i.pas` ==> There are 12 unit tests in the graph1_test directory.
    Samples are in the graph1_sample directory.
2. `pasrec.pas` ==> There are 35 unit tests in the pasrec_test directory.
    Samples are in the pasrec_sample directory.
3. Each unit test worths 2 points. The rest 6 points are free.
4. You can get partial points (0.5, 1, 1.5) if your output is partially correct.
5. The grade is based on these unittests. 
   You got points off if your output is wrong even it is caused by your parser 
   and/or lexer. 
   You are working on a compiler now, so everything can cause you trouble.
6. The grading is based on matching assembly code. 
   I will not run your assembly code. 
   However, the sample output is just a reference. 
   You can still get all points if your assembly code makes sense even if it looks 
   different from the sample. 
   (Chances are you implement some optimizations, reorder some computations, have 
   a different symbol table so that the offset of vars are all different)
7. You might get extra points for clever optimizations.
8. I will grade your codegen on the **cs machine** using **clang** as the compiler. 

To check your code generator on the test files, cd to the autograder directory 
and run
```
./codegen_autograder.sh workingdir
```
where `workingdir` is where you put all your code.

## Submissions

1. lexan.l   // if you forgot, I will use the latest lexan.l from your submission
2. parse.y   // if you forgot, I will use the parse.y from your project 5
3. codegen.c // if you forgot, you will get a 0 for this project!!!
4. any other files that are modified. // if you forgot and this leads to compilation 
   error or seg fault, you will get a 0 for this project!!!

## Note --- Effect of pprint.c on the generated code

I added two functions, `removeExtraProgn()` and `exprCanonicalization()`, in 
`ppexpr()` in pprint.c. 
These two functions change the structure of the parse tree, rather than doing some
tricks when printing the parse tree in `printexpr()`.
The intention of these two functions is to eliminate alternatives in the structure
of the parse tree so that it is easier for the autograder to do comparisons.
In addition, `exprCanonicalization()` can also affect the assembly code generated 
by the code generator, i.e. it can affect the number of register used.
I will use pasrec_test/test16_00.pas as an example to illustrate how `exprCanonicalization()` 
reduces the number of registers used by the code.

The offset of the aref structure on the left hand side of the assignment is `48*i-8`. 
If the parser does not apply any policy on the look of the parse tree, the result 
if this offset can be
```
   +
  / \
-8   *
    / \
   48  i
```
When assigning registers for this subtree, -8 will be assigned to %eax, 
48 will be assigned to %ecx, and i will be assigned to %edx. 
Therefore, 3 registers are required to generate the assembly code.

What `exprCanonicalization()` does is to switch `-8` and `*` in the parse tree.
Therefore, the output is 
```
     +
    / \ 
   *  -8
  / \
 i  48
```
In this case, i will be assigned to %eax and 48 will be assigned to %ecx. 
Then the multiplication instruction will update %eax as the result of 48*i
and release %ecx.
As a result, -8 will be assigned to %ecx, thus reducing the total number of registers
required to 2.

Note that `exprCanonicalization()` also switches 48 and i, which does not affect 
the number of registers in the code.

It is assumed that `genarith()` will always work on the left child of an operator 
subtree first. 
The key to reduce the number of registers is to work on the **big** child first.

This version of pprint.c is used for grading only.
You can ignore it or comment out those two functions when you write and test your
code. 
If you happen to implement `genarith()` in the way that it works on the right child
first, you will not lose points for using more registers.

The last thing to note is that the parse tree manipulation functions work only when
```
ppexpr(parseresult);
```
is called in main() in parse.y. 
If you comment this function out in main(), the autograder will add it for grading
purpose only. 
