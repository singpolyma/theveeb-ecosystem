search: search.o getopt.o get_paths.o
	gcc -lsqlite3 -o search getopt.o get_paths.o search.o
	strip -x search

getopt.o: getopt.c
	gcc -c -O3 -Wextra -Wall -Werror -ansi -pedantic -o getopt.o getopt.c

get_paths.o: get_paths.c
	gcc -c -O3 -Wextra -Wall -Werror -ansi -pedantic -o get_paths.o get_paths.c

search.o: search.c
	gcc -c -O3 -Wextra -Wall -Werror -ansi -pedantic -o search.o search.c
 
.PHONY: clean distclean
 
clean:
	rm -f search search.o getopt.o

distclean: clean

