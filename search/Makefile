CC=gcc
TARGET=unix
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic -DTARGET=$(TARGET)
GETOPT=

ifeq ($(TARGET),win32)
	CFLAGS+= -D_WIN32 -D__WIN32__ -DTVEDB="\"C:\\\\Program Files\\\\TheVeeb\\\\var\\\\cache\\\\tve.db\""
	GETOPT=getopt.o
endif

ifeq ($(TARGET),osx)
	CFLAGS+= -DTVEDB=\"/Library/Caches/tve.db\"
endif

search: search.o get_paths.o $(GETOPT)
	$(CC) -lsqlite3 -o search $(GETOPT) get_paths.o search.o
	strip -x search

getopt.o: getopt.c
	$(CC) $(CFLAGS) getopt.c

get_paths.o: get_paths.c
	$(CC) $(CFLAGS) get_paths.c

search.o: search.c
	$(CC) $(CFLAGS) search.c
 
.PHONY: clean distclean
 
clean:
	$(RM) search *.o

distclean: clean
