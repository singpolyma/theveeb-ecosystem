#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlite3.h>

int print_results(void * dummy, int field_count, char ** row, char ** fields) {
	char status = ' ';
	char * end;
	if((end = strchr(row[3], '\n'))) {
		*end = '\0';
	}
	if(row[0] != NULL) {
		switch(atoi(row[0])) {
			case 1: status = 'I'; break;
			case -1: status = 'U'; break;
		}
	}
	printf("%c %-25s %-15s %s\n", status, row[1], row[2], row[3]);
	return 0;
}

int main (int argc, char ** argv ) {
	sqlite3 * db;
	char * err;
	if(sqlite3_open("test.db", &db) != 0) {
		puts(sqlite3_errmsg(db));
	}
	sqlite3_exec(db, "SELECT status,package,version,description FROM packages", &print_results, NULL, &err);
	sqlite3_free(err);
	if(sqlite3_close(db) != 0) {
		puts(sqlite3_errmsg(db));
	}
	return 0;
}
