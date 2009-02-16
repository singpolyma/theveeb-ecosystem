CC=gcc
STRIP=strip -x
TARGET=unix
CFLAGS=-O3 -Wextra -Wall -Werror -ansi -pedantic -DTARGET=$(TARGET)
LDFLAGS=-lsqlite3
GETOPT=

#ifeq is not POSIX. Other versions of make may require you to set these flags by hand.

ifeq ($(TARGET),win32)
	CFLAGS+= -D_WIN32 -D__WIN32__ -DTVEDB="\"C:\\\\Program Files\\\\TheVeeb\\\\var\\\\cache\\\\tve.db\""
	GETOPT=getopt.o
endif

ifeq ($(TARGET),osx)
	CFLAGS+= -DTVEDB=\"/Library/Caches/tve.db\"
endif

search: search.o get_paths.o $(GETOPT)
	$(CC) $(LDFLAGS) -o $@ search.o get_paths.o $(GETOPT)
	$(STRIP) $@

.PHONY: clean distclean
 
clean:
	$(RM) search *.o

distclean: clean
