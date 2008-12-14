md5main: md5main.o
	gcc -lsqlite3 -o md5main md5.o md5main.o
	strip -s md5main
 
md5.o: md5.c
	gcc -c -O3 -Wall -Werror -ansi -pedantic -o md5.o md5.c

md5main.o: md5main.c md5.o
	gcc -c -O3 -Wall -Werror -ansi -pedantic -o md5main.o md5main.c
 
.PHONY: clean distclean
 
clean:
	rm -f md5main md5main.o md5.o

distclean: clean

