CC=clang

lexanc:  lexandr.o lexanc.o scanner.o printtoken.o token.h lexan.h
	$(CC) -o lexanc lexandr.o lexanc.o scanner.o printtoken.o -lm

printtoken.o: printtoken.c token.h
	$(CC) -c printtoken.c

scanner.o: scanner.c token.h lexan.h
	$(CC) -c scanner.c

lexanc.o: lexanc.c token.h lexan.h
	$(CC) -c lexanc.c
