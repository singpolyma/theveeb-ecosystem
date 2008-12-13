get: get.o
	gcc -lcurl -o get get.o
	strip -s get
 
get.o: get.c
	gcc -c -O3 -Wall -Werror -ansi -pedantic -o get.o get.c
 
.PHONY: clean distclean
 
clean:
	rm -f get get.o

distclean: clean

