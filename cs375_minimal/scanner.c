/* scanner.c            C Version of Scanner          ; 11 Jul 12    */

/* Copyright (c) 2012 Gordon S. Novak Jr., Hiow-Tong Jason See, and
   The University of Texas at Austin. */

/* 09 Feb 01    */

/* Routines for use with CS 375 Lexical Analyzer assignment.
   Contains auxiliary functions for peeking and getting characters,
   and for initializing a character class array.                     */

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

#include <stdio.h>
#include <ctype.h>

#include "token.h"
#include "lexan.h"

int EOFFLG;

int CHARCLASS[MAXCHARCLASS];              /* character class array */
char specchar[] = "+-*/:=<>^.,;()[]{}";   /* initialize special characters */

void initscanner ()
  {  EOFFLG = 0;
  }

/* getchar() is included in stdio.h .  Returns EOF at end of file. */

int peekchar()          /* Peek at next character without moving pointer */
  { int c;
    c = getchar();
    ungetc(c,stdin);
    return c;
    }

int peek2char()         /* Peek at second character without moving pointer */
  { int c, cc;
    c = getchar();
    cc = getchar();
    ungetc(cc,stdin);
    ungetc(c,stdin);
    return cc;
    }

void init_charclass()   /* initialize character class array */
  { int i;
    for (i = 0; i < MAXCHARCLASS; ++i) CHARCLASS[i] = 0;
    for (i = 'A'; i <= 'Z'; ++i)       CHARCLASS[i] = ALPHA;
    for (i = 'a'; i <= 'z'; ++i)       CHARCLASS[i] = ALPHA;
    for (i = '0'; i <= '9'; ++i)       CHARCLASS[i] = NUMERIC;
    for (i = 0 ; specchar[i] != '\0';  ++i) CHARCLASS[specchar[i]] = SPECIAL;
    }

/* Get the next token from the input.
   This is the interface from the parser to the lexical analyzer. */
TOKEN gettoken()
  {   int c, cclass;
      TOKEN tok = (TOKEN) talloc();   /* = new token */
      skipblanks();     /* and comments */
      if ((c = peekchar()) != EOF)
          {
            cclass = CHARCLASS[c];
            if (cclass == ALPHA)
              identifier(tok);
            else if (cclass == NUMERIC)
                    number(tok);
                    else if (c == '\'')
                            getstring(tok);
                            else special(tok);
          }
          else EOFFLG = 1;
     if (DEBUGGETTOKEN != 0) printtoken(tok);
     return(tok);
  }
