CC=gcc
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

md5main: md5main.o md5.o
	$(CC) -o md5 md5.o md5main.o
	strip -x md5
 
md5.o: md5.c
	$(CC) $(CFLAGS) md5.c

md5main.o: md5main.c
	$(CC) $(CFLAGS) md5main.c
 
.PHONY: clean distclean
 
clean:
	$(RM) md5main md5main.o md5.o

distclean: clean

