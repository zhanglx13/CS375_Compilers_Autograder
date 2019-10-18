## CC=clang -fPIC
CC=cc

parser: y.tab.o lex.yy.o printtoken.o pprint.o symtab.o
	$(CC) -o parser y.tab.o lex.yy.o printtoken.o pprint.o symtab.o -ll

y.tab.c: parse.y token.h parse.h symtab.h lexan.h
	yacc parse.y

y.tab.o: y.tab.c
	$(CC) -c y.tab.c -Wall

pprint.o: pprint.c token.h
	$(CC) -c pprint.c -Wall

symtab.o: symtab.c token.h symtab.h
	$(CC) -c symtab.c -Wall

lexanc:  lexandr.o lexanc.o scanner.o printtoken.o token.h lexan.h
	$(CC) -o lexanc lexandr.o lexanc.o scanner.o printtoken.o -lm

printtoken.o: printtoken.c token.h
	$(CC) -c printtoken.c

scanner.o: scanner.c token.h lexan.h
	$(CC) -c scanner.c

lexanc.o: lexanc.c token.h lexan.h
	$(CC) -c lexanc.c

lexer:  lex.yy.o lexanl.o printtoken.o token.h lexan.h
	$(CC) -o lexer lex.yy.o lexanl.o printtoken.o

lexanl.o: lexanl.c token.h lexan.h
	$(CC) -c lexanl.c

lex.yy.o: lex.yy.c
	$(CC) -c lex.yy.c -Wall

lex.yy.c: lexan.l token.h
	lex lexan.l

parsec: parsc.o lexanc.o scanner.o printtoken.o pprint.o symtab.o
	$(CC) -o parsec parsc.o lexanc.o scanner.o printtoken.o pprint.o symtab.o

parsc.o: parsc.c lexan.h token.h symtab.h parse.h
	$(CC) -c parsc.c
