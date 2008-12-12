#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sqlite3.h>

int getopt(int argc, char * const argv[], const char *optstring);
extern char *optarg;
extern int optind, opterr, optopt;

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
	printf("%c %-35s %-25s %s\n", status, row[1], row[2], row[3]);
	return 0;
}

int main (int argc, char ** argv) {
	sqlite3 * db = NULL;
	char sql[200] = "\0";
	char * query = NULL;
	int c;

	while((c = getopt(argc, argv, "-ld:")) != -1) {
		switch(c) {
			case 'l':
				sql[0] = 1;
				break;
			case 'd':
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case '\1':
				query = optarg;
				break;
			default:
				/* TODO: write usage message */
				fprintf(stderr, "Fatal.\n");
				exit(EXIT_FAILURE);
		}
	}

	if(db == NULL && sqlite3_open("test.db", &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	if(query == NULL) {
		/* Why can't this just be an assignment? */
		strcpy(sql, "SELECT status,package,version,description FROM packages");
	} else {
		/* Static buffers are retarded, block long searches */
		if(strlen(query) > 85) {
			fprintf(stderr,"Your query is too long.\n");
			exit(EXIT_FAILURE);
		}

		if(sql[0] == '\0') {
			sprintf(sql, "SELECT status,package,version,description FROM packages WHERE package LIKE '%%%s%%' OR description LIKE '%%%s%%'", query, query);
		} else {
			sprintf(sql, "SELECT status,package,version,description FROM packages WHERE package LIKE '%%%s%%'", query);
		}
	}

	if(sqlite3_exec(db, sql, &print_results, NULL, NULL) != 0) {
		fprintf(stderr, "Malformed query (you may have included a single-quote, or the specified database may not exist).\n");
		exit(EXIT_FAILURE);
	}

	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	return 0;
}
