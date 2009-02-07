search: search.o
	gcc -lsqlite3 -o search getopt.o search.o
	strip -x search

getopt.o: getopt.c
	gcc -c -O3 -Wextra -Wall -Werror -ansi -pedantic -o getopt.o getopt.c

search.o: search.c getopt.o
	gcc -c -O3 -Wextra -Wall -Werror -ansi -pedantic -o search.o search.c
 
.PHONY: clean distclean
 
clean:
	rm -f search search.o getopt.o

distclean: clean

