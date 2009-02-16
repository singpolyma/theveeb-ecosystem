CC=gcc
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

update: update.o getopt.o
	$(CC) -lsqlite3 -o update getopt.o update.o
	strip -s update
 
getopt.o: getopt.c
	$(CC) $(CFLAGS) getopt.c

update.o: update.c
	$(CC) $(CFLAGS) update.c
 
.PHONY: clean distclean
 
clean:
	$(RM) update update.o getopt.o

distclean: clean
