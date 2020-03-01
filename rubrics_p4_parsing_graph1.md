# Rubrics for project 4 --- graph1(i).pas

## Grading

Same as the [grading section of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#grading) except that the parsing output will be compared with `graph1.sample`. 
I will use `graph1i.pas` as input for grading. 

# Rubrics

- 2 points for each constant in the symbol table, 10 points in total.
- 2 points for each constant (which should be replaced by its literal value) in the output tree, 10 points in total.
- 5 points for the repeat construct.
- 5 points for makefloat: for (float i), s*y, and round() + h.
- 5 points for makefix: for round() + h (you do not have to worry about this bullet if you use graph1i.pas as input).
- If your parser works fine for trivb.pas, there should not be any other errors. If there is any, each costs 2 points.
- -2 points for each token whose basicdt is incorrectly assigned (see details below).
- -5 for each bug caused by bad programming style. (see [details in the rubrics of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#bad-programming-styles))

# Submissions

Same as the [submissions section of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#submissions).

## Notes

Make sure you read the [note of project 3](https://github.com/zhanglx13/CS375_Compilers_Autograder/blob/master/rubrics_p3_parsing_trivb.md#notes).

### Token Type
Each token in the parse tree should have a type if its type is used later.
For numbers and ids with basic data type, their basicdt are assigned by the lexer. For binary operations, the operator's basicdt should also be properly assigned.
E.g. the parse tree for 3+5 is like follows
```
      +    // TOKEN plusTok
     /
    /
   3 ----- 5
```
Then you should have
```
plusTok->basicdt = INTEGER;
```
This is called **type propagation**. 
You also need to figure out the basicdt of funcall if the function returns a numeric value. (Hint: you can look up a function's name in the symbol table and obtain its return type accordingly. Make sure you read `symtab.txt`.)
Type propagation is the foundation of the success for type coercion. 
Make sure you get it right.
