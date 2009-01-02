update: update.o
	gcc -lsqlite3 -o update getopt.o update.o
	strip -s update
 
getopt.o: getopt.c
	gcc -c -O3  -o getopt.o getopt.c

update.o: update.c getopt.o
	gcc -c -O3 -o update.o update.c
 
.PHONY: clean distclean
 
clean:
	rm -f update update.o getopt.o

distclean: clean

