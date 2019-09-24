CC=clang -fPIC

lexanc:  lexandr.o lexanc.o scanner.o printtoken.o token.h lexan.h
	$(CC) -o lexanc lexandr.o lexanc.o scanner.o printtoken.o -lm

printtoken.o: printtoken.c token.h
	$(CC) -c printtoken.c

scanner.o: scanner.c token.h lexan.h
	$(CC) -c scanner.c

lexanc.o: lexanc.c token.h lexan.h
	$(CC) -c lexanc.c

lexer:  lex.yy.o lexanl.o printtoken.o token.h lexan.h
	cc -o lexer lex.yy.o lexanl.o printtoken.o

lexanl.o: lexanl.c token.h lexan.h
	cc -c lexanl.c

lex.yy.o: lex.yy.c
	cc -c lex.yy.c -Wall

lex.yy.c: lexan.l token.h
	lex lexan.l
