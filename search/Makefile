CC=gcc
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

search: search.o getopt.o get_paths.o
	gcc -lsqlite3 -o search getopt.o get_paths.o search.o
	strip -x search

getopt.o: getopt.c
	$(CC) $(CFLAGS) -o getopt.o getopt.c

get_paths.o: get_paths.c
	$(CC) $(CFLAGS) -o get_paths.o get_paths.c

search.o: search.c
	$(CC) $(CFLAGS) -o search.o search.c
 
.PHONY: clean distclean
 
clean:
	$(RM) search search.o getopt.o

distclean: clean
