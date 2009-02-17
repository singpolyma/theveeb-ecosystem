CC=gcc
STRIP=strip -x
TARGET=unix
LDFLAGS=-lsqlite3
CFLAGS=-c -O3 -Wextra -Wall -Werror -ansi -pedantic -DTARGET=$(TARGET)
GETOPT=

ifeq ($(TARGET),win32)
	CFLAGS+= -D_WIN32 -D__WIN32__ -DTVEDB="\"\\\\Program Files\\\\TheVeeb\\\\var\\\\cache\\\\tve.db\""
	GETOPT=getopt.o
endif

ifeq ($(TARGET),osx)
	CFLAGS+= -DTVEDB=\"/Library/Caches/tve.db\"
endif

update: update.o get_paths.o $(GETOPT)
	$(CC) $(LDFLAGS) -o $@ update.o get_paths.o $(GETOPT)
	$(STRIP) $@
 
.PHONY: clean distclean
 
clean:
	$(RM) update *.o

distclean: clean
