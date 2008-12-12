search: search.o
	gcc -lsqlite3 -o search search.o
 
search.o: search.c
	gcc -c -Wall -Werror -ansi -pedantic -o search.o search.c
 
.PHONY: clean distclean
 
clean:
	rm -f search search.o

distclean: clean

