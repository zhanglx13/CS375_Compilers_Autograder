CC=clang
compiler: y.tab.o lex.yy.o printtoken.o pprint.o symtab.o codegen.o genasm.o
	$(CC) -o compiler y.tab.o lex.yy.o printtoken.o pprint.o symtab.o codegen.o genasm.o

compc: parsc.o lexanc.o scanner.o printtoken.o pprint.o symtab.o codegen.o genasm.o
	$(CC) -o compc parsc.o lexanc.o scanner.o printtoken.o pprint.o symtab.o codegen.o genasm.o

codegen.o: codegen.c token.h symtab.h genasm.h
	$(CC) -c codegen.c -Wall

genasm.o: genasm.c token.h symtab.h genasm.h
	$(CC) -c genasm.c

parser: y.tab.o lex.yy.o printtoken.o pprint.o symtab.o
	$(CC) -o parser y.tab.o lex.yy.o printtoken.o pprint.o symtab.o -lm

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
