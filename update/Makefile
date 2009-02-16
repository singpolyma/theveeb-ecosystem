CC=gcc
STRIP=strip -x
LDFLAGS=-lsqlite3
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

update: update.o getopt.o
	$(CC) $(LDFLAGS) -o $@ getopt.o update.o
	$(STRIP) $@
 
.PHONY: clean distclean
 
clean:
	$(RM) update *.o

distclean: clean
