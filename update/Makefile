CC=gcc
STRIP=strip -x
LDFLAGS=-lsqlite3
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic

update: update.o getopt.o get_paths.o
	$(CC) $(LDFLAGS) -o $@ getopt.o update.o get_paths.o
	$(STRIP) $@
 
.PHONY: clean distclean
 
clean:
	$(RM) update *.o

distclean: clean
