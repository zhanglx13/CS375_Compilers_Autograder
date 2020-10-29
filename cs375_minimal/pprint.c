/*  pprint.c                Gordon S. Novak Jr.          ; 11 Jan 18  */

/*  Pretty-print a token expression tree in Lisp-like prefix form    */

/* Copyright (c) 2018 Gordon S. Novak Jr. and
   The University of Texas at Austin. */

/*  This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/ */

/*  For PROGRAM, the code should look like:
     PROGRAM
       /
     GRAPH1---->PROGN---->code
                  /
               OUTPUT                  */

/* 09 Feb 01; 17 May 13  */

#include <ctype.h>
#include <stdio.h>
#include "token.h"
#include "lexan.h"
#include "pprint.h"

#define PRINTEXPRDEBUG 0     /* Set to 1 to print each node in printexpr */

char* opprint[]  = {" ", "+", "-", "*", "/", ":=", "=", "<>", "<", "<=",
                      ">=", ">",  "^", ".", "and", "or", "not", "div", "mod",
                      "in", "if", "goto", "progn", "label", "funcall",
                      "aref", "program", "float", "fix"};
int opsize[] = {1, 1, 1, 1, 1, 2, 1, 2, 1, 2,
                  2, 1, 1, 1, 3, 2, 3, 3, 3,
                  2, 2, 4, 5, 5, 7,
                  4, 7, 5, 3 };

void debugprinttok(TOKEN tok)           /* print a token for debugging */
  { if (tok == NULL)
       printf(" token NULL%ld\n", (long)tok);
     else printf(
      " token %ld  typ %2d  whic %3d  dty %3d  sty %ld lnk %ld  opnds %ld\n",
      (long)tok, tok->tokentype, tok->whichval, tok->basicdt,
      (long)tok->symtype, (long)tok->link, (long)tok->operands);
  }

int strlength(char str[])           /* find length of a string */
  {  int i, n;
     n = 16;
     for (i = 0; i < 16; i++)
         if ( str[i] == '\0' && n == 16 ) n = i;
     return n;
   }

void printtok(TOKEN tok)             /* print a token in abbreviated form */
{
    switch (tok->tokentype)
	{
    case IDENTIFIERTOK:
        printf ("%s", tok->stringval);
        break;
    case STRINGTOK:
        printf ("'%s'", tok->stringval);
        break;
    case NUMBERTOK:
        switch (tok->basicdt)
        {
        case INTEGER:
        case POINTER:
            printf ("%d", tok->intval);
            break;
        case REAL:
            printf ("%e", tok->realval);
            break; };
        break;
    case OPERATOR:
        printf ("%s", opprint[tok->whichval]);
        break;
    case DELIMITER:
        printf ("del %d", tok->whichval);
        break;
    case RESERVED:
        printf ("res %d", tok->whichval);
        break;
    }
}

void dbugprinttok(TOKEN tok)  /* print a token in 'nice' debugging form */
  { if (tok == NULL)
       printf(" token %ld  NULL\n", (long)tok);
       else switch (tok->tokentype)
	     { case IDENTIFIERTOK:
	              printf(" token %ld  ID  %12s  dtype %2d  link %ld\n",
                             (long)tok, tok->stringval, tok->basicdt,
                             (long)tok->link);
		      break;
	       case STRINGTOK:
	              printf(" token %ld  STR %12s  dtype %2d  link %ld\n",
                     (long)tok, tok->stringval, tok->basicdt, (long)tok->link);
		      break;
	       case NUMBERTOK:
		 switch (tok->basicdt)
		   {case INTEGER: case POINTER:
		      printf(" token %ld  NUM %12d  dtype %2d  link %ld\n",
                      (long)tok, tok->intval, tok->basicdt, (long)tok->link);
		      break;
		    case REAL:
		      printf(" token %ld  NUM %12e  dtype %2d  link %ld\n",
                      (long)tok, tok->realval, tok->basicdt, (long)tok->link);
		      break; };
                      break;
		    case OPERATOR:
	     printf(" token %ld  OP  %12s  dtype %2d  link %ld  operands %ld\n",
                      (long)tok, opprint[tok->whichval], tok->basicdt,
                      (long)tok->link, (long)tok->operands);
		      break;
		    case DELIMITER: case RESERVED:
		      debugprinttok(tok);
		      break;
	 }
  }

void printexpr(TOKEN tok, int col)     /* print an expression in prefix form */
{
    TOKEN opnds;
    int nextcol, start;
    int lhsIsAref = 0;
    if (PRINTEXPRDEBUG != 0)
    {
        printf ("printexpr: col %d\n", col);
        dbugprinttok(tok);
    };
    if (tok->tokentype == OPERATOR)
    {
        opnds = tok->operands;
        nextcol = col + 2 + opsize[tok->whichval];
        printf ("(%s", opprint[tok->whichval]);
        start = 0;
        while (opnds != NULL)
        {
            if (start == 0)
                printf(" ");
            else if (start == 1)
            {
                printf("\n");
                //for (int i = 0; i < nextcol; i++) printf(" ");
            }
            printexpr(opnds, nextcol);
            /*
             * Other formats for better visualization
             */
            start = 1;
            if (tok->whichval == FUNCALLOP)
                start = 0;
            if (tok->whichval < 12)
                start = 0;
            if (tok->whichval == AREFOP)
                start = 0;
            if ((opnds->tokentype == OPERATOR) && (opnds->whichval == FUNCALLOP))
                start = 1;
            if ( opnds->tokentype == IDENTIFIERTOK)
                nextcol += 1 + strlength(opnds->stringval);
            if ((opnds->tokentype == OPERATOR) && (opnds->whichval == AREFOP))
                lhsIsAref = 1;
            else
                lhsIsAref = 0;
            opnds = opnds->link;
            if (opnds != NULL && (opnds->tokentype == OPERATOR) && (opnds->whichval == AREFOP) && (lhsIsAref))
                start = 1;
        }
        printf (")");
    }
    else printtok(tok);
}

/*
 * markSkippedProgn is called recursively to mark all progn's in the subtree
 * rooted at tok. The marking is done by setting its basicdt to 99
 *
 * @param tok a subtree root token
 */
void markSkippedProgn(TOKEN tok)
{
    /*
     * If the tok is a progn, we check all its stmts. If any of them is a
     * progn, set its basicdt to 99
     */
    if ( (tok->tokentype == OPERATOR) && (tok->whichval == PROGNOP)){
        TOKEN stmt = tok->operands;
        while (stmt)
        {
            if ( (stmt->tokentype == OPERATOR) && (stmt->whichval == PROGNOP))
                stmt->basicdt = 99;
            stmt = stmt->link;
        }
    }
    /*
     * For any token, markSkippedProgn needs to be called recursively
     */
    TOKEN child = tok->operands;
    if (child != NULL)
        markSkippedProgn(child);
    TOKEN sibling = tok->link;
    if (sibling != NULL)
        markSkippedProgn(sibling);
}

/*
 * Remove all marked progn's in the parse tree
 *
 * @param root a subtree root token
 */
void removeMarkedProgn(TOKEN root)
{
    /* First we check if root's operands needs to be removed */
    if (root->operands != NULL){
        while (root->operands->basicdt == 99){
            /*
             *     root
             *      /
             *     X -> n -> O
             *    /
             *   m -> O -> O -> p
             *
             *  To move token X in the above parse tree, the following needs to be done:
             *  1. root->operands = m
             *  2. p->link = n
             *  Note that n can be NULL. But m and p must not be NULL.
             */
            TOKEN X = root->operands;
            TOKEN n = X->link;     // can be NULL
            TOKEN m = X->operands; // cannot be NULL
            TOKEN p = m;           // cannot be NULL
            while (p->link != NULL)
                p = p->link;
            root->operands = m;
            p->link = n;
        }
        /*
         * Now the operands of root is "clean", we need to call removeMarkedProgn
         * recursively on it.
         */
        removeMarkedProgn(root->operands);
    }
    // Then we check if root's link needs to be removed
    if (root->link != NULL){
        while (root->link->basicdt == 99){
            /*
             *   root ->  X -> n -> O
             *           /
             *          m -> O -> O -> p
             *
             *  To move token X in the above parse tree, the following needs to be done:
             *  1. root->link = m
             *  2. p->link = n
             *  Note that n can be NULL. But m and p must not be NULL.
             */
            TOKEN X = root->link;
            TOKEN n = X->link;     // can be NULL
            TOKEN m = X->operands; // cannot be NULL
            TOKEN p = m;           // cannot be NULL
            while (p->link != NULL)
                p = p->link;
            root->link = m;
            p->link = n;
        }
        /*
         * Now the link of root is "clean", we need to call removeMarkedProgn
         * recursively on it
         */
        removeMarkedProgn(root->link);
    }
}

/*
 * Remove unnecessary progn's in the parse tree
 *
 * @param root a subtree root token
 */
void removeExtraProgn(TOKEN root)
{
    /* First we mark all progn's that can be removed*/
    markSkippedProgn(root);
    /* Then we remove marked progn's */
    removeMarkedProgn(root);
}

/*
 * Set priority of some tokens
 *
 * 0 ==> TIMESOP
 * 1 ==> IDENTIFIERTOK
 * 2 ==> NUMBERTOK
 *
 * double is used for priority to facilitate future change.
 * Other tokens are assigned -1.0.
 *
 * @param tok a token whose priority will be assined
 */
double setPriority(TOKEN tok)
{
    if (tok->tokentype == OPERATOR && tok->whichval == TIMESOP)
        return 0.0;
    if (tok->tokentype == IDENTIFIERTOK)
        return 1.0;
    if (tok->tokentype == NUMBERTOK)
        return 2.0;
    return -1.0;
}

/*
 * switch the operands of the given op if the lhs and rhs follows:
 *
 * 1. lhs is NUMBERTOK and rhs is *
 * 2. lhs is NUMBERTOK and rhs is IDENTIFIERTOK
 * 3. lhs is IDENTIFIERTOK and rhs is *
 *
 * The logic is to keep high priority operands to the left and we are currently
 * implementing the following priority:
 *
 * NUMBER < ID < *
 *
 * @param op a binary operator token
 */
void switchOperands(TOKEN op)
{
    TOKEN lhs = op->operands;
    if (lhs == NULL)
        return;
    TOKEN rhs = lhs->link;
    /* return if unary operation */
    if (rhs == NULL)
        return;
    /* return if any of the operands' priority is not set */
    if ((setPriority(lhs) == -1.0) || (setPriority(rhs) == -1.0))
        return;
    if (setPriority(lhs) > setPriority(rhs)){
        op->operands = rhs;
        rhs->link = lhs;
        lhs->link = NULL;
    }
}

/*
 * Recursively canonicalize all arithmetic expressions
 *
 * @param root a subtree root token
 */
void exprCanonicalization(TOKEN root)
{
    if ((root->tokentype == OPERATOR) &&
        (root->whichval == PLUSOP ||
         root->whichval == MINUSOP || // Note that MINUSOP can be used in an unary operation
         root->whichval == TIMESOP ||
         root->whichval == DIVIDEOP)){
        switchOperands(root);
    }
    /*
     * Whether root is a binary operator or not, call exprCanonicalization
     * recursively on its operands and links
     */
    if (root->operands != NULL)
        exprCanonicalization(root->operands);
    TOKEN tmp = root->link;
    while (tmp){
        exprCanonicalization(tmp);
        tmp = tmp->link;
    }
}

void ppexpr(TOKEN tok)       /* pretty-print an expression in prefix form */
{
    /*
     * Before calling printexpr, we do some processing on the parse tree.
     * Note that this is better than doing so in printexpr, since any debug info
     * in the pre-processing functions does not affect the printed out parse
     * tree. Thus the autograder does not mind if we forgot to turn off any
     * of those debug info.
     */
    removeExtraProgn(tok);
    exprCanonicalization(tok);
    if ( (long) tok <= 0 )
    {
        printf("ppexpr called with bad pointer %ld\n", (long)tok);
	return;
    }
    printexpr(tok, 0);
    printf("\n");
}

TOKEN debugtoken = NULL;    /* dummy op for printing a list */

void pplist(TOKEN tok)              /* pretty-print a list in prefix form */
  { if ( debugtoken == NULL )
      { debugtoken = talloc();
        debugtoken->whichval = 0; }  /* will print as blank */
    debugtoken->operands = tok;
    ppexpr(debugtoken);
  }

void dbugplist(TOKEN tok)           /* print a list of tokens for debugging */
  { while (tok != NULL)
      { dbugprinttok(tok);
        tok = tok->link;
      };
  }

void dbugbprinttok(TOKEN tok)    /* print rest of token for debugging */
  { if (tok != NULL)
      printf("  toktyp %6d  which  %6d  symtyp %ld  syment %ld  opnds %ld\n",
	     tok->tokentype, tok->whichval, (long)tok->symtype,
             (long)tok->symentry, (long)tok->operands);
  }

void dbugprintexpr(TOKEN tok) /* print an expression in 'nice' debugging form */
  { TOKEN opnds;
    dbugprinttok(tok);
    if (tok->tokentype == OPERATOR)
      { opnds = tok->operands;
	while (opnds != NULL)
	      { dbugprintexpr(opnds);
		opnds = opnds->link;
	      }
      }
  }
