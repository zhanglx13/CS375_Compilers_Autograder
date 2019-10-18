/* symtab.c            Gordon S. Novak Jr.            ; 15 Feb 18    */

/* Symbol Table Code and Data for Pascal Compiler */
/* See the documentation file, symtab.txt         */

/* Copyright (c) 2018 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/* 09 Feb 01; 21 Feb 07; 06 Aug 09; 19 Jul 12; 26 Jul 12; 30 Jul 12;
   02 Aug 12; 24 Dec 12; 13 May 13; 10 Oct 16 */

/*
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program; if not, see <http://www.gnu.org/licenses/>.
  */


/* To use:  1. Call initsyms() once to initialize basic symbols.

            2. Call insertsym(string) to insert a new symbol,
                e.g. insertsym(tok->stringval);
                returns a symbol table pointer, of type SYMBOL.

               makesym and symalloc will also be used.

	    3. Call searchst(string) to search for a symbol,
                e.g. searchst(tok->stringval);
                returns a symbol table pointer, of type SYMBOL.
  */

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "symtab.h"
#include "token.h"
#include "pprint.h"


/* BASEOFFSET is the offset for the first variable */
#define BASEOFFSET 0

int    blocknumber = 0;       /* Number of current block being compiled */
int    contblock[MAXBLOCKS];  /* Containing block for each block        */
int    blockoffs[MAXBLOCKS];  /* Storage offsets for each block         */
SYMBOL symtab[MAXBLOCKS];     /* Symbol chain for each block            */
SYMBOL symend[MAXBLOCKS];     /* End of symbol chain for each block     */

/* Sizes of basic types  INTEGER  REAL  STRINGTYPE  BOOLETYPE  POINTER   */
int basicsizes[5] =      { 4,       8,       1,         4,        8 };

char* symprint[10]  = {" ", "BASIC", "CONST", "VAR", "SUBRANGE",
                       "FUNCTION", "ARRAY", "RECORD", "TYPE", "POINTER"};
int symsize[10] = { 1, 5, 5, 3, 8, 8, 5, 6, 4, 7 };


SYMBOL symalloc()           /* allocate a new symbol record */
  { 
    return((SYMBOL) calloc(1,sizeof(SYMBOLREC)));
  }

/* Make a symbol table entry with the given name */
SYMBOL makesym(char name[])
  { SYMBOL sym; int i;
    sym = symalloc();
    for ( i = 0; i < 16; i++) sym->namestring[i] = name[i];
    sym->link = NULL;
    return sym;
  }

/* Insert a name in the symbol table at current value of blocknumber */
/* Returns pointer to the new symbol table entry, which is empty     */
/* except for the name.                                              */
SYMBOL insertsym(char name[])
  { SYMBOL sym;
    sym = makesym(name);
    if ( symtab[blocknumber] == NULL )  /* Insert in 2-pointer queue */
       symtab[blocknumber] = sym;
       else symend[blocknumber]->link = sym;
    symend[blocknumber] = sym;
    sym->blocklevel = blocknumber;
    if (DEBUG) printf("insertsym %8s %ld\n", name, (long) sym);
    return sym;
  }

/* Search one level of the symbol table for the given name.         */
/* Result is a pointer to the symbol table entry or NULL            */
SYMBOL searchlev(char name[], int level)
  { SYMBOL sym;
    sym = symtab[level];
    while ( sym != NULL && strcmp(name, sym->namestring) != 0 )
      sym = sym->link;
    return sym;
  }

/* Search all levels of the symbol table for the given name.        */
/* Result is a pointer to the symbol table entry or NULL            */
SYMBOL searchst(char name[])
  { SYMBOL sym; int level;
    level = blocknumber;
    sym = NULL;
    while ( sym == NULL && level >= 0 )
          {  sym = searchlev(name, level);
             if (level > 0) level = contblock[level]; /* try containing block */
                else level = -1;                      /* until all are tried  */
	   }
    if (DEBUG) printf("searchst  %8s %ld\n", name, (long) sym);
    return sym;
  }

/* Search for symbol, insert if not there. */
SYMBOL searchins(char name[])
  {  SYMBOL res;
     res = searchst(name);
     if ( res != NULL ) return(res);
     res = insertsym(name);
     return(res);
   }

/* Get the alignment boundary for a type  */
int alignsize(SYMBOL sym)
{     switch (sym->kind)
      { case BASICTYPE: case SUBRANGE:
          return sym->size;
          break;
	case POINTERSYM:
	  return 8;
          break;
	case ARRAYSYM:
	case RECORDSYM:
	  return 16;
          break;
        default:
	  return 8;
          break;
      }
}

/* Print one symbol table entry for debugging      */
void dbprsymbol(SYMBOL sym)
 { if( sym != NULL )
   printf(" %ld  %10s knd %1d %1d  typ %ld lvl %1d  siz %5d  off %5d lnk %ld\n",
          (long)sym, sym->namestring, sym->kind, sym->basicdt,
          (long)sym->datatype,
       sym->blocklevel, sym->size, sym->offset, (long)sym->link);
   }

void pprintsym(SYMBOL sym, int col)   /* print type expression in prefix form */
  { SYMBOL opnds; int nextcol, start, done, i;
    if (sym == NULL)
      { printf ("pprintsym: called with sym = NULL\n");
        return; }
    if (PPSYMDEBUG != 0)
      { printf ("pprintsym: col %d\n", col);
        dbprsymbol(sym);
      };
    switch (sym->kind)
      { case BASICTYPE:
          printf("%s", sym->namestring);
          nextcol = col + 1 + strlength(sym->namestring);
          break;
        case SUBRANGE:
          printf("%3d ..%4d", sym->lowbound, sym->highbound);
          nextcol = col + 10;
          break;
	case POINTERSYM:
	  if (sym->datatype->namestring != 0)
	    printf("(^ %s)", sym->datatype->namestring);
	  else printf("(^ %ld)", (long)sym->datatype);
          break;
	case FUNCTIONSYM:
	case ARRAYSYM:
	case RECORDSYM:
          printf ("(%s", symprint[sym->kind]);
          nextcol = col + 2 + symsize[sym->kind];
          if ( sym->kind == ARRAYSYM )
            {  printf(" %3d ..%4d", sym->lowbound, sym->highbound);
               nextcol = nextcol + 11;
	     }
          opnds = sym->datatype;
	  start = 0;
          done = 0;
	  while ( opnds != NULL && done == 0 )
	    { if (start == 0) 
		 printf(" ");
	         else { printf("\n");
			for (i = 0; i < nextcol; i++) printf(" ");
		      };
	      if ( sym->kind == RECORDSYM )
		 {  printf("(%s ", opnds->namestring);
		    pprintsym(opnds, nextcol + 2
			             + strlength(opnds->namestring));
		    printf(")");
		 }
	        else pprintsym(opnds, nextcol);
	      start = 1;
              if ( sym->kind == ARRAYSYM ) done = 1;
	      opnds = opnds->link;
	    }
	  printf(")");
          break;
        default:
          if ( sym->datatype != NULL) pprintsym(sym->datatype, col);
             else printf("NULL");
          break;
      }
  }

void ppsym(SYMBOL sym)             /* print a type expression in prefix form */
  { pprintsym(sym, 0);
    printf("\n");
  }

/* Print one symbol table entry       */
void printsymbol(SYMBOL sym)
  {  if (sym == NULL)
      { printf ("printsymbol: called with sym = NULL\n");
        return; }
     switch (sym->kind)
       { case FUNCTIONSYM: case ARRAYSYM:
         case RECORDSYM: case POINTERSYM:
           printf(
             " %ld  %10s  knd %1d %1d  typ %ld  lvl %2d  siz %5d  off %5d\n",
                  (long)sym, sym->namestring, sym->kind, sym->basicdt,
                  (long)sym->datatype,
                  sym->blocklevel, sym->size, sym->offset);
           ppsym(sym);
         break;
         case VARSYM:
           if (sym->datatype->kind == BASICTYPE)
              printf(
               " %ld  %10s  VAR    %1d typ %7s  lvl %2d  siz %5d  off %5d\n",
                  (long)sym, sym->namestring, sym->basicdt,
                     sym->datatype->namestring,
                  sym->blocklevel, sym->size, sym->offset);
              else printf(
                 " %ld  %10s  VAR    %1d typ %ld  lvl %2d  siz %5d  off %5d\n",
                  (long)sym, sym->namestring, sym->basicdt,
                 (long)sym->datatype,
                  sym->blocklevel, sym->size, sym->offset);
           if (sym->datatype->kind != BASICTYPE ) ppsym(sym->datatype);
         break;
         case TYPESYM:
           printf(" %ld  %10s  TYPE   typ %ld  lvl %2d  siz %5d  off %5d\n",
                  (long)sym, sym->namestring, (long)sym->datatype,
                  sym->blocklevel, sym->size, sym->offset);
           if (sym->datatype->kind != BASICTYPE ) ppsym(sym->datatype);
         break;
         case BASICTYPE:
           printf(" %ld  %10s  BASIC  basicdt %3d          siz %5d\n",
                  (long)sym, sym->namestring, sym->basicdt, sym->size);
         break;
	 case SUBRANGE:
           printf(" %ld  %10s  SUBRA  typ %7d  val %5d .. %5d\n",
		  (long)sym, sym->namestring, sym->basicdt,
		  sym->lowbound, sym->highbound);
         break;
         case CONSTSYM:
           switch (sym->basicdt)
	     {  case INTEGER:
                  printf(" %ld  %10s  CONST  typ INTEGER  val  %d\n",
                         (long)sym, sym->namestring, sym->constval.intnum);
		  break;
	        case REAL:
                  printf(" %ld  %10s  CONST  typ    REAL  val  %12e\n",
                         (long)sym, sym->namestring, sym->constval.realnum);
		  break;
	        case STRINGTYPE:
                  printf(" %ld  %10s  CONST  typ  STRING  val  %12s\n",
                         (long)sym, sym->namestring, sym->constval.stringconst);
		  break;
		}
         break;
	};
  }

/* Print entries on one level of symbol table */
void printstlevel(int level)
  { SYMBOL sym;
      sym =  symtab[level];
      if ( sym != NULL )
	{ printf("Symbol table level %d\n", level);
	  while ( sym != NULL )
	    { printsymbol(sym);
	      sym = sym->link;
	    };
	};
  }

/* Print all entries in the symbol table */
void printst()
  { int level;
    for ( level = 0; level < MAXBLOCKS; level++) printstlevel(level);
  }

/* Insert a basic type into the symbol table */
SYMBOL insertbt(char name[], int basictp, int siz)
  { SYMBOL sym;
    sym = insertsym(name);
    sym->kind = BASICTYPE;
    sym->basicdt = basictp;
    sym->size = siz;
    return sym;
  }

/* Insert a one-argument function in the symbol table. */
/* Linked to the function symbol are result type followed by arg types.  */
SYMBOL insertfn(char name[], SYMBOL resulttp, SYMBOL argtp)
  { SYMBOL sym, res, arg;
    sym = insertsym(name);
    sym->kind = FUNCTIONSYM;
    res = symalloc();
    res->kind = ARGSYM;
    res->datatype = resulttp;
    if (resulttp != NULL) res->basicdt = resulttp->basicdt;
    arg = symalloc();
    arg->kind = ARGSYM;
    arg->datatype = argtp;
    if (argtp != NULL) arg->basicdt = argtp->basicdt;
    arg->link = NULL;
    res->link = arg;
    sym->datatype = res;
    return sym;
  }

/* Call this to initialize symbols provided by the compiler */
void initsyms()
  {  SYMBOL sym, realsym, intsym, charsym, boolsym;
     blocknumber = 0;               /* Put compiler symbols in block 0 */
     blockoffs[1] = BASEOFFSET;     /* offset of first variable */
     realsym = insertbt("real", REAL, 8);
     intsym  = insertbt("integer", INTEGER, 4);
     charsym = insertbt("char", STRINGTYPE, 1);
     boolsym = insertbt("boolean", BOOLETYPE, 4);
     sym = insertfn("exp", realsym, realsym);
     sym = insertfn("trexp", realsym, realsym);
     sym = insertfn("sin", realsym, realsym);
     sym = insertfn("cos", realsym, realsym);
     sym = insertfn("trsin", realsym, realsym);
     sym = insertfn("sqrt", realsym, realsym);
     sym = insertfn("round", realsym, realsym);
     sym = insertfn("iround", intsym, realsym); /* C math lib defines round */
     sym = insertfn("ord", intsym, intsym);
     sym = insertfn("new", intsym, intsym);
     sym = insertfn("trnew", intsym, intsym);
     sym = insertfn("write", NULL, charsym);
     sym = insertfn("writeln", NULL, charsym);
     sym = insertfn("writef", NULL, realsym);
     sym = insertfn("writelnf", NULL, realsym);
     sym = insertfn("writei", NULL, intsym);
     sym = insertfn("writelni", NULL, intsym);
     sym = insertfn("read", NULL, NULL);
     sym = insertfn("readln", NULL, NULL);
     sym = insertfn("eof", boolsym, NULL);
     blocknumber = 1;             /* Start the user program in block 1 */
     contblock[1] = 0;
   }
