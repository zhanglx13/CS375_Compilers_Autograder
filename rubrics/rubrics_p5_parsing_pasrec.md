# Rubrics for project 5 --- pasrec.pas

## Grading and Rubrics

**Your code will be checked for plagiarism against each other as well as some online github code using moss. If you get caught, you will get a 0 for this project.**

The grading of this project is divided into the following two parts:

1. `pasrec.pas` ==> There are 15 unit tests in the test_p5 directory. Each test 
   is extracted from pasrec.pas (or something similar) and focuses on one part 
   of it. Each unit test is worth 6 points (90 points in total). You can get
   partial points of only part of the result is correct. 
   A description and hint of each unit test can be found in `test_p5_hints.sh`.
   The samples are in the sample_p5 directory. Naming convention is summarized
   [here](https://github.com/zhanglx13/CS375_Compilers_Autograder#tests-and-samples).
2. `graph1i.pas` ==> 10 points. Please make sure your new parser can still 
   handle graph1i.pas.
   
You should also read [grading section of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#grading)
for other common grading notes.

To check your parser on the test files, you need to first compile  the symbol
table checker in symTable as follows
```
cd symTable
make
```
Then you need to cd back to the autograder dir and run
```
./parser_autograder.sh p5 workingdir
```
where `workingdir` is where you put all your code.

## Submissions

Same as the [submissions section of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#submissions).

## Notes

Make sure you read the [note of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#notes) 
and the [notes of project 4](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p4_parsing_graph1.md#notes)

Here are some more notes for this project

### Make sure you initialize everything before using it

Let's say you are trying to reduce `ac[7].re`. 
After you figure out that `ac[7]` is a complex, you probably need to go through 
its field list to locate `re` using an index `i`. 
If you messed up with `ac[7]`, which means the pointers of the `recordsym` is 
not properly set, you will not find `re` in the field list. 
However, if you do not initialize `i`, its value could be set to 0 by some compiler. 
In this case, it seems to you that the 0th field matches `re` and you happen 
to get the correct result.

### Make sure you set the type of `aref` properly

When you do type coercion for 
```
john^.location.re := 3;
```
The lhs will be converted to 
```
(aref (^ john) 16)
```
Then the correctness of type coercion will depend on the type of aref.
In general, if `aref` refers to a complex type, such as RECORD, POINTER, the 
**symtype** field of `aref` should be properly set. If `aref` refers to a basic 
type, such as real and integer, the **basicdt** field of `aref` should also be 
properly set. 

For the next project --- codegen, if the type of `aref` is not properly set, 
the wrong register might be chosen for the `aref` structure. So make sure 
you get this right.
