search: search.o
	gcc -lsqlite3 -o search getopt.o search.o
	strip -s search

getopt.o: getopt.c
	gcc -c -O3  -o getopt.o getopt.c

search.o: search.c getopt.o
	gcc -c -O3  -o search.o search.c
 
.PHONY: clean distclean
 
clean:
	rm -f search search.o getopt.o

distclean: clean

