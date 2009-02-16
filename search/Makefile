CC=gcc
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

search: search.o getopt.o get_paths.o
	$(CC) -lsqlite3 -o search getopt.o get_paths.o search.o
	strip -x search

getopt.o: getopt.c
	$(CC) $(CFLAGS) getopt.c

get_paths.o: get_paths.c
	$(CC) $(CFLAGS) get_paths.c

search.o: search.c
	$(CC) $(CFLAGS) search.c
 
.PHONY: clean distclean
 
clean:
	$(RM) search search.o getopt.o

distclean: clean
