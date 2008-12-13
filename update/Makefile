update: update.o
	gcc -lsqlite3 -o update update.o
	strip -s update
 
update.o: update.c
	gcc -c -O3 -Wall -Werror -ansi -pedantic -o update.o update.c
 
.PHONY: clean distclean
 
clean:
	rm -f update update.o

distclean: clean

