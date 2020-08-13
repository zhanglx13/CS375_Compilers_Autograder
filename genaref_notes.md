# Some notes about genaref()

Here is what genarith looks like
```
int genarith(TOKEN code){
...
  case OPERATOR:
    if (code->whichval == AREFOP)
      return genaref(code, -1);
    if (other operators ....
  ...
}
```
This call to genaref handles the case when aref is on the rhs of :=, i.e. we need 
the value at the address represented by the aref structure and allocate a new 
register to hold the value.

Note that in this case, `storereg` is -1 (any value below 0 should work)

And in genc(), you have the following case
```
void genc(TOKEN code){
  switch (code->whichval){
    case ASSIGNOP:
      reg=genarith(rhs);
      if (lhs->tokentype == OPERATOR && lhs->whichval == AREFOP)
        genaref(lhs, reg);
	other cases ....
  }
}
```
This handles the case when aref is on the lhs of :=. i.e. the value in reg will be 
put in the address represented by the aref structure. 

Note that in this case, `storereg` is the reg allocated for the rhs of the assignment.

## Implementation of `genaref(TOKEN code, int storereg)`

Three cases to consider:

- `(aref baseID offtok)`

    1. get the `offset` of baseID ==> baseID's offset in the symbol table - stkframesize
    2. get a reg for `offtok` by calling genarith(offtok), the returned reg is `reg0`
    3. if aref on the **left** (storereg >=0), use asmstrr() with `storereg`, `reg0`, `offset`. Return -1.
    Note that asmstrr is needed because %rbp should be used for the symbol table.
    4. if aref on the **right** (storereg <0), get a new `reg1` and use asmldrr() with `reg0`, `reg1`, and `offset`. Return `reg1`.
    

- `(aref (^ ptr) offtok)`

    1. get the `offset` of ptr ==> ptr's offset in the symbol table - stkframesize
    2. get a new `reg0` and call asmld with `reg0` and `offset` to dereference the pointer ptr.
    3. if aref on the **left** (storereg >=0), use asmstr() with `storereg`, `reg0`, `offoffset`. Return -1. Here `offoffset=offtok->intval`.
    Note that asmstr is used here because the addressing does not need %rbp. When dereferencing the pointer with asmld, %rbp is used for the pointer.
    4. if aref on the **right** (storereg <0), get a new `reg1` and use asmldr() with `reg0`, `reg1`, and `offoffset`. Return reg1. Here `offoffset=offtok->intval`.
    To simplify the programming workload for this project, in 3 and 4, you can use offtok->intval as the offset, which means the offset in this case is always an integer. 

- `(aref (^ aref ...) offtok)` Let say the first aref is `aref0` and second aref is `aref1`. 

    1. call `genaref(aref1, -1)` and return the result in `reg0`
    2. the rest follows step 3 in the above case

When you allocate a new register in genaref, you need code's type to determine which register to use.

