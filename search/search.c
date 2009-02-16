#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlite3.h>
#include "get_paths.h"

#if defined(_WIN32) || defined(__WIN32__)
	#include "getopt.h"
#else
	#include <unistd.h>
	int getopt(int argc, char * const argv[], const char *optstring);
	extern char *optarg;
	extern int optind, opterr, optopt;
#endif

#ifndef EXIT_SUCCESS
	#define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
	#define EXIT_FAILURE -1
#endif

/* Print usage message */
void help() {
	puts(
"search for packages\n"
"Usage: search [OPTION] [QUERY]\n"
"   QUERY           Pattern to search for\n"
"   -h              help menu (this screen)\n"
"   -l              list (search package names only)\n"
"   -v              verbose (more complete output)\n"
"   -i[category]    category/section to restrict search to\n"
"   -x[category]    category/section to exclude from results\n"
"   -s[field]       field to sort by\n"
"   -d[path]        path to database file\n"
	);
	exit(EXIT_FAILURE);
}

/* Callback for query: print row */
int print_results(void * dummy, int field_count, char ** row, char ** fields) {
	char status = ' ';
	char * end;
	if(dummy && field_count && fields) {} /* Supress "unused parameters" warning. */
	if((end = strchr(row[3], '\n'))) {
		*end = '\0';
	}
	if(row[0] != NULL) {
		switch(atoi(row[0])) {
			case 1: status = 'I'; break;
			case -1: status = 'U'; break;
		}
	}
	printf("%c %-20s %-10s %s\n", status, row[1], row[2], row[3]);
	return 0;
}

/* Callback for query: print row (verbose) */
int print_results_verbose(void * dummy, int field_count, char ** row, char ** fields) {
	if(dummy && field_count && fields) {} /* Supress "unused parameters" warning. */
	printf("Package: %s\n", row[1]);
	if(row[0] != NULL) {
		switch(atoi(row[0])) {
			case 1: puts("Status: installed"); break;
			case -1: puts("Status: update available"); break;
		}
	} else {
		puts("Status: not installed");
	}
	printf("Version: %s\n", row[2]);
	printf("Description: %s\n", row[3]);
	puts("");
	return 0;
}


int main (int argc, char ** argv) {
	sqlite3 * db = NULL;
	char sql[250] = "\0";
	char * query = NULL;
	char * include_cats = NULL;
	char * exclude_cats = NULL;
	char * order_by = "package";
	char * db_path = NULL;
	int verbose = 0;
	int c;

	while((c = getopt(argc, argv, "-lvhi:x:s:d:")) != -1) {
		switch(c) {
			case 'l': /* Search package names only */
				sql[0] = 1;
				break;
			case 'v':
				verbose = 1;
				break;
			case 'i':
				include_cats = optarg;
				break;
			case 'x':
				exclude_cats = optarg;
				break;
			case 's':
				order_by = optarg;
				break;
			case 'd': /* Specify database */
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case '\1': /* Search query */
				query = optarg;
				break;
			case 'h': /* Usage message and exit */
			default:
				help();
		}
	}

	if(db == NULL && (db_path = get_db_path()) && sqlite3_open(db_path, &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}
	if(db_path) {
		free(db_path);
	}

	if(query == NULL) {
		strcpy(sql, "SELECT status,package,version,description FROM packages WHERE 1=1");
	} else {
		if(strchr(query, '\'') != NULL) {
			fprintf(stderr, "Malformed query (single-quote not allowed).\n");
			exit(EXIT_FAILURE);
		}

		/* Static buffers are retarded, block long searches */
		if(strlen(query) > 43) {
			fprintf(stderr,"Your query is too long.\n");
			exit(EXIT_FAILURE);
		}

		if(sql[0] == '\0') {
			sprintf(sql, "SELECT status,package,version,description FROM packages WHERE (package LIKE '%%%s%%' OR description LIKE '%%%s%%')", query, query);
		} else {
			sprintf(sql, "SELECT status,package,version,description FROM packages WHERE package LIKE '%%%s%%'", query);
		}
	}

	if(include_cats) {
		strcat(sql, " AND (section='");
		strcat(sql, include_cats);/* FIXME: split by comma and support multiple cats */
		strcat(sql, "' OR category='");
		strcat(sql, include_cats);/* FIXME: split by comma and support multiple cats */
		strcat(sql, "')");
	}

	if(exclude_cats) {
		strcat(sql, " AND (section!='");
		strcat(sql, exclude_cats);/* FIXME: split by comma and support multiple cats */
		strcat(sql, "' AND category!='");
		strcat(sql, exclude_cats);/* FIXME: split by comma and support multiple cats */
		strcat(sql, "')");
	}

	strcat(sql, " ORDER BY ");
	strcat(sql, order_by);

	if(verbose) {
		if(sqlite3_exec(db, sql, &print_results_verbose, NULL, NULL) != 0) {
			fprintf(stderr, "Malformed query (The specified database may not exist).\n");
			exit(EXIT_FAILURE);
		}
	} else {
		if(sqlite3_exec(db, sql, &print_results, NULL, NULL) != 0) {
			fprintf(stderr, "Malformed query (The specified database may not exist).\n");
			exit(EXIT_FAILURE);
		}
	}

	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
