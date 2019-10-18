/* lexandr.c         Gordon S. Novak Jr.    10 Feb 04; 31 May 12       */

/* This is a driver program for testing the lexical analyzer written in C. */

/* Copyright (c) 2012 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/* 
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/* To use:
   1. make lex1                uses the starter file lex1.c
   2. lex1
      123 3578   01247
or:
   1. make lexanc              uses the file lexan.c
   2. lexanc <graph1.pas
                   */

#include <stdio.h>
#include <ctype.h>
#include "token.h"
#include "lexan.h"

void testscanner()
  { TOKEN tok;
    while (EOFFLG == 0)
      {
        tok = gettoken();
        if (EOFFLG == 0) printtoken(tok);
      }
  }

/*          main for testing    */
int main()
   {   
       initscanner();
       init_charclass();                    /* init the scanner */
       printf("Started scanner test.\n");
       testscanner();
   }
