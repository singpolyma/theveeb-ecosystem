CC=gcc
STRIP=strip -x
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic
LDFLAGS=

md5main: md5main.o md5.o
	$(CC) $(LDFLAGS) -o $@ md5.o md5main.o
	$(STRIP) $@
 
.PHONY: clean distclean
 
clean:
	$(RM) md5main *.o

distclean: clean

