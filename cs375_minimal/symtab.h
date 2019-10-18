/* symtab.h            Gordon S. Novak Jr.           ; 10 Oct 16 */

/* Symbol Table Record and Definitions */

/* Copyright (c) 2016 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/* 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

/* 21 Feb 07; 01 Aug 12; 03 Aug 12; 24 Dec 12

 */

/* The symbol table is designed to handle a tree of symbols, with
   inheritance of symbols from parent scopes of the tree.
   Each 'level' is one node (lexical scope) of the tree.
   For the class project, there are only two levels:
     level 0: symbols such as integer, real, sin, ... known to the compiler
     level 1: symbols of the Pascal program
 */

/* Define kinds of symbols.  The kind field should be one of these. */
#define ARGSYM       0
#define BASICTYPE    1
#define CONSTSYM     2
#define VARSYM       3
#define SUBRANGE     4
#define FUNCTIONSYM  5
#define ARRAYSYM     6   
#define RECORDSYM    7
#define TYPESYM      8
#define POINTERSYM   9

/* The following defines are commented out, but may be needed.
#define INTEGER    0
#define REAL       1
#define STRINGTYPE 2
#define BOOLETYPE  3
#define POINTER    4
    */

#define PPSYMDEBUG 0

#define MAXBLOCKS 50          /* Max number of program blocks           */

typedef struct symtbr {
  struct symtbr *link;
  char   namestring[16];
  int    kind;                /* kind of symbol -- see defines. */
  int    basicdt;             /* type code for basic data types       */
  struct symtbr *datatype;    /* pointer for more complex data types  */
  int    blocklevel;
  int    size;
  int    offset;
  union  { char  stringconst[16];
	   int   intnum;
           double realnum; } constval;
  int    lowbound;
  int    highbound;
  } SYMBOLREC, *SYMBOL;

/* symalloc makes a new symbol table record and returns a pointer to it.
   Essentially     new Symbol()   */
SYMBOL symalloc(void);

/* makesym makes a new symbol table record and puts a name into it.
   Use makesym e.g. for record field names. */
SYMBOL makesym(char name[]);

/* insertsym makes a new symbol table record, puts a name into it,
   and puts it into the symbol table.
   Use insertsym e.g. for variables and type names. */
SYMBOL insertsym(char name[]);

SYMBOL searchlev(char name[], int level);

/* search the symbol table for the given name.
   Returns a pointer to the symbol table entry if found. */
SYMBOL searchst(char name[]);

/* search the symbol table for the given name.
   Returns a pointer to the symbol table entry if found.
   If not found, a new symbol with the given name is created.
   Use this one for type names. */
SYMBOL searchins(char name[]);

/* Print one symbol table entry for debugging      */
void dbprsymbol(SYMBOL sym);

void pprintsym(SYMBOL sym, int col);

/* pretty-print a type in the symbol table */
void ppsym(SYMBOL sym);

/* Print one symbol table entry       */
void printsymbol(SYMBOL sym);

/* Print entries on one level of symbol table */
void printstlevel(int level);

/* Print all entries in the symbol table */
void printst(void);

SYMBOL insertbt(char name[], int basictp, int siz);
SYMBOL insertfn(char name[], SYMBOL resulttp, SYMBOL argtp);
void initsyms(void);    /* initializes pre-defined symbols */

/* alignsize returns the required alignment boundary for a type  */
int alignsize(SYMBOL sym);

int DEBUG;
int blocknumber;           /* Number of current block being compiled */
int blockoffs[MAXBLOCKS];  /* Storage offsets for each block         */
int basicsizes[5];
