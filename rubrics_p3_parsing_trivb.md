# Rubrics for project 3 --- trivb.pas

## Grading

Your parsing output will be compared with `trivb.sample`. However, your parser's output might differ in the following ways:

- It is preferred that you do not print symbol table level 0. This is done by changing `printst()` to `printstlevel(1)` in the `main()` function in parse.y.
- For symbol table level 1, `i` and `lim` should be there but the order does not matter. Also, the address of each symbol can be different.
- For the result tree, you can have extra `progns` but the parenthesis should always match.
- Extra newlines or different indentation is also acceptable, you can change the layout of your tree by modifying pprint.c.
- You may use `printf()` to debug your parser. Please make sure you turn off all debugging info in parse.y before submitting it.
- The following line in trivb.sample does not matter. You can control whether to print it by setting `DB_PARSERES`.
```
token 25592784  OP       program  dtype  0  link 0  operands 25589968
```

I will use the files in the `/cs375_minimal` folder for grading your parser. 
Here are the notes you might want to keep in mind:

- I made some changes in pprint.c and printtoken.c to facilitate the grading process. If you submit pprint.c or printtoken.c, they are not used for grading. 
- I will use clang to compile your code.
- I will run your parser on the cs machine.


 
## Rubrics

- 5 points for each symbol in the symbol table level 1.
- 4 points for each line of the result parse tree.
- -5 for each bug caused by bad programming style. (see detail below)


## Submissions

- parse.y (if you use Yacc) or parsc.c (if you use C)
- lexan.l (If you forget to do so, I will use what you submitted for project 2)
- Any other files that you modify.
Please submit **INDIVIDUAL FILES** rather than a single compressed package.

## Notes

### Cooperation of Yacc, Lex, and your parse.y:

To start project 3 (trivb.pas), you first copy pars1.y into parse.y.
Inside parse.y you will find the `main()` function at the end. Inside the `main()` function, `yyparse()` is called, which performs the parsing of the input program.

YACC will generate y.tab.c after you run `yacc parse.y`. Inside y.tab.c, `yyparse()` is implemented. Inside `yyparse()`, the input token is provided by function `yylex()`, which is defined in lex.yy.c. Lex will generate lex.yy.c after you run `lex lexan.l`.
Although you can implement `yylex()` function by yourself, leaving it to Lex makes your life much easier.

All the above commands are combined in the following single command
```
make parser
```
which is what you should do to compile your parser for the following three projects.

### Debugging

#### Using `printf`

Unfortunately, the most efficient debugging mechanism is to use printf for this class. 
You might also want to use those functions defined in pprint.c to help you print token information. 
There is one thing about using printf to locate a seg fault. See the following example:
```c
printf("Can we get here?\n");
xxx //<--- statement that causes a seg fault
```
Chances are you will not see the message even you put printf before the seg fault. Therefore, you are fooled to think that the seg fault happens somewhere before.
The reason is that output to stdout is buffered, which means the printf puts some chars into a buffer instead of on the screen. For usually program execution, you will see all printf result on the screen in their original order but with a delay. If the program receives a seg fault signal before flushing the buffer to the screen, the content in the buffer is lost (from your perspective). 
The solution is to flush the buffer explicitly after printf (as follows) so that you should be able to see every printf's result before the seg fault happens.
```c
printf("Can we get here?\n");
fflush(stdout);
xxx //<--- statement that causes a seg fault
```

#### Enabling the parser-trace feature of YACC 
I know, I know, I know that seeing a **syntax error** is the most frustrated thing when you do your projects. 
A syntax error means that your grammar does not match the input Pascal code.
(Yes, you need to make your grammar match the input program, not the other way around when you develop applications.)
The usually way to debug a syntax error is to look at the grammar very carefully, which is time consuming.

Alternatively, YACC can generate parsing information, from which it is much easier to find out what causes the syntax error. 
Here is what you need to do to print out trace information.

1. Compile your parser with trace information.
You can add `-t` flag to yacc in line 139-140 in the original makefile or line 17-18 in the compacted makefile I provided as follows
```
y.tab.c: parse.y token.h parse.h symtab.h lexan.h
    yacc -t parse.y
```
2. Request a trace when your parser parses an input program.
You can request a trace by setting `yydebug` to a non-zero value.
You can simply do it in the beginning of the `main()` function in parse.y as follows
```c
int main(void)
{
    yydebug=1;
    int res;
    initsyms();
    res = yyparse();
    // printst();
    printstlevel(1);
    printf("yyparse result = %8d\n", res);
    if (DEBUG & DB_PARSERES) dbugprinttok(parseresult);
    ppexpr(parseresult);           /* Pretty-print the result tree */
    /* uncomment following to call code generator. */
    //gencode(parseresult, blockoffs[blocknumber], labelnumber);
}
```

When you run your parser with the input program, trace messages will be printed out before the symbol table information.
The trace messages tell you these things:

1. Each time the parser calls yylex, what kind of token was read.
2. Each time a token is shifted, the depth and complete contents of the state stack.
3. Each time a rule is reduced, which rule it is, and the complete contents of the state
stack afterward.

Read the [Bison manual](https://www.gnu.org/software/bison/manual/) chapter 8.4 for more details.

#### Using gdb to locate segmentation fault
Besides **syntax error**, another frustrating error of your parser must be the **segmentation fault**,
which is usually caused by dereferencing a pointer that is not properly set.
See the example below
```
TOKEN makerepeat(TOKEN tok, TOKEN statements, TOKEN tokb, TOKEN expr)
{
  int *ptr = NULL;
  printf("%d\n", *ptr);
  ......
}
```
When I run the parser with graph1.pas, it receives a segfault signal. 
To locate the bug, you can use gdb as follows

1. Compile your parser with `-g` flag so that gdb can have source code information.
The `-g` flag should be added to the following command in the makefile
```
y.tab.o: y.tab.c
        $(CC) -c -g y.tab.c -Wall
```
2. run gdb with your parser as follows
```
gdb parser
```
And this is what you see on the CS machine
```
GNU gdb (Ubuntu 8.1-0ubuntu3.2) 8.1.0.20180409-git
Copyright (C) 2018 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<http://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
<http://www.gnu.org/software/gdb/documentation/>.
For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from parser...done.
(gdb)
```
Then run your parser with graph1.pas using `r < graph1.pas` as follows
```
(gdb) r < graph1.pas
Starting program: /u/lxzhang/parser < graph1.pas
```
```
Program received signal SIGSEGV, Segmentation fault.
0x0000555555559031 in makerepeat (tok=0x55555576c310, statements=0x55555576c390, 
    tokb=0x55555576c5d0, expr=0x55555576c650) at parse.y:1114
1114	printf("%d\n", *ptr);
(gdb) 
```
The output tells that the segmentation fault is caused as line 1114 in parse.y and it 
even prints that line for you to investigate.



### Bad Programming Styles

#### Undefined values:

If a variable is not initialized before its first use, the value is undefined according to the C standard. 
Different compilers may take different actions to uninitialized variables. E.g. gcc may set uninitialized variables to 0 while clang may leave uninitialized variables whatever value is in the memory location. 
It is considered a bad programming style to assume uninitialized variables to have value 0.

A similar situation is when you try to access a location that is out of the bound of an array.
The data there is also undefined.

A good way to detect such potential bugs is to let the compiler to help.
You can add `-Wall` at the end of line 143 in the original makefile as follows
```
y.tab.o: y.tab.c
    cc -c y.tab.c -Wall
```
and read the warnings carefully if they are generated from parse.y or y.tab.c.
(Note that the `-Wall` is already added in the compact makefile.)

This is also the reason why I made some change in the `talloc()` function defined in printtoken.c as follows
```c
TOKEN talloc()           /* allocate a new token record */
{ 
    TOKEN tok;
    tok = (TOKEN) calloc(1,sizeof(struct tokn));
    if ( tok != NULL ){
        tok->tokentype = 9999;
        tok->basicdt = 9999;
        /*
         * In this way, the initial value of the union becomes
         *
         * string: ################
         * int/which: 589505315
         * real:   0.00000
         *
         * The point of doing so is that now the string
         * does not have any '\0' initially. Therefore,
         * if '\0' is not explicitly placed in the string.
         * the string won't stop when being printed.
         */
        for (int i=0; i<16; i++)
            tok->stringval[i]=35;
        return (tok);
    }
    else {
        printf("talloc failed."); return 0;
    }
}
```

#### Return of Non-void Functions

If you forgot to write a return token for the following function (which links two tokens together)
```c
TOKEN myFunc(TOKEN a, TOKEN b){
  a->link = b;
}
```
And use it as follows
```c
TOKEN new_a = myFunc(a,b);
```
The value of `new_a` is undefined.
On some OS+Compiler platforms, you get `a` as the return token, which is the desired result.
However, on some other OS+Compiler platforms, you can get `b` as the returned token.
Here OS+Compiler platform means one of the following combinations:

- Linux + gcc
- Linux + clang
- MacOS + gcc
- MacOS + clang
- MacOS + Apple Clang


Another issue can arise when you define a new TOKEN in one of the branches of if statement such as
```c
TOKEN makefloat(TOKEN tok)
{
    TOKEN result;
    if (tok->intval > 10)
        result = tok;
    else
    {
        TOKEN result = talloc();
        result->intval = -10;
    }
    return result;
}
```
The returned value can be an uninitialized value on `makefloat`'s stack if the else branch is taken.
For more details of this bug, check this [stackoverflow post](https://stackoverflow.com/questions/59166218/different-compiler-behaviors-for-uninitialized-data-on-the-stack).

Using `-Wall` as suggested above should also help you detect such errors.


