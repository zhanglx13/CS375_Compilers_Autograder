# Rubrics for project 3 --- trivb.pas

## Grading

Your parsing output will be compared with `trivb.sample`. However, your parser's output might differ in the following ways:

- It is preferred that you do not print symbol table level 0. This is done by changing `printst()` to `printstlevel(1)` in the `main()` function in parse.y.
- For symbol table level 1, `i` and `lim` should be there but the order does not matter. Also, the address of each symbol can be different.
- For the result tree, you can have extra `progns` but the parenthesis should always match.
- Extra newlines or different indentation is also acceptable, you can change the layout of your tree by modifying pprint.c.
- You may use `printf()` to debug your parser. Please make sure you turn off all debugging info in parse.y before submitting it.

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

There is another way to see how your parser works.
If you add `-t` flag to yacc in line 139-140 in the original makefile or line 17-18 in the compacted makefile I provided as follows
```
y.tab.c: parse.y token.h parse.h symtab.h lexan.h
    yacc -t parse.y
```
and add `yydebug=1` in the beginning of the `main()` function in parse.y, you can see the steps (reduce and shift) your parser performs on the input when you run your parser in the
normal way.

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


