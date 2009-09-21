#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <sqlite3.h>
#include "common/get_paths.h"
#include "common/version_compare.h"

#if defined(_WIN32) || defined(__WIN32__)
	#include "common/getopt.h"
#else
	#include <unistd.h>
	int getopt(int argc, char * const argv[], const char *optstring);
	extern char *optarg;
	extern int optind, opterr, optopt;
#endif

/* Status values */
#define STATUS_NOT_SET         100
#define UP_TO_DATE             101 /* Magic value flag to say the package is up-to-date */
#define NOT_INSTALLED            0
#define INSTALLED                1
#define DEPENDENCY               2
#define NEEDS_UPDATE            -1
#define DEPENDENCY_NEEDS_UPDATE -2

/* Print usage message */
void help() {
	puts("search for packages");
	puts("Usage: search [OPTION] [QUERY]");
	puts("   QUERY           Pattern to search for");
	puts("   -h              help menu (this screen)");
	puts("   -o              query ownership status");
	puts("   -d[path]        path to database file");
}

/* Callback for query: print row */
int print_results(void * status, int field_count, char ** row, char ** fields) {
	(void)fields;
	(void)field_count;
	if(row[0] == NULL) {
		row[0] = "0";
	}
	if(*((int*)status) == UP_TO_DATE) {
		errno = 0;
		*((int*)status) = strtol(row[0], NULL, 10);
		if(*((int*)status) < 0) {
			*((int*)status) *= -1;
		}
		if(*((int*)status) == 0) {
			*((int*)status) = 1;
		}
		if(errno) {
			fputs("Fatal error.", stderr);
			exit(EXIT_FAILURE);
		}
	} else {
		printf("%s\n",row[0]);
	}
	return 0;
}

int print_o_results(void *dummy, int field_count, char **row, char **fields) {
	(void)dummy;
	(void)field_count;
	(void)fields;
	if(row[1] == NULL || row[1][0] == '\0') {
		puts("0");
	} else if(version_compare(row[0], row[1]) <= 0) {
		puts("1");
	} else {
		puts("0");
	}
	return 0;
}

int main (int argc, char ** argv) {
	sqlite3 * db = NULL;
	char * db_path = NULL;
	char * package = NULL;
	char sql[150];
	int status = STATUS_NOT_SET;
	int c;
	int ownMode = 0;

	while((c = getopt(argc, argv, "-12hod:")) != -1) {
		switch(c) {
			case 'd': /* Specify database */
				/*XXX We might want to sanity-check that the database does
				    actually exist.   --DV
				*/
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case 'o': /* Check Own Status Instead */
				ownMode = 1;
				break;
			/* Hacks to pass in negative numbers */
			case '1':
				status = -1;
				break;
			case '2':
				status = -2;
				break;
			case '\1': /* package and maybe status */
				/*XXX Not a very sensible way to handle possible multiple
				    search query arguments.   --DV
				*/
				if(package == NULL) {
					package = optarg;
				} else if(status == STATUS_NOT_SET) {
					if(optarg[0] == '.') {
						status = UP_TO_DATE;
					} else {
						errno = 0;
						status = strtol(optarg, NULL, 10);
						if(errno || status > 2 || status < -2) {
							fputs("Invalid status.\n", stderr);
							exit(EXIT_FAILURE);
						}
					}
				} else {
					help();
					exit(EXIT_FAILURE);
				}
				break;
			case 'h': /* Usage message and exit */
				help();
				exit(EXIT_SUCCESS);
			default:  /* Unrecognized option */
				help();
				exit(EXIT_FAILURE);
		}
	}

	/* On non-GNU systems, we won't have the arguments yet */
	if(package == NULL && optind < argc) {
		package = argv[optind++];
	}

	if(status == STATUS_NOT_SET && optind < argc) {
		if(argv[optind][0] == '.') {
			status = UP_TO_DATE;
		} else {
			errno = 0;
			status = strtol(argv[optind], NULL, 10);
			if(errno || status > 2 || status < -2) {
				fputs("Invalid status.", stderr);
			}
		}
	}

	/* Must specify a package */
	if(package == NULL || package[0] == '\0' || package[0] == '-') {
		help();
		exit(EXIT_FAILURE);
	}
	if(strlen(package) > 50) {
		fputs("Package names are not longer than 50 characters.", stderr);
		exit(EXIT_FAILURE);
	}

	/* Get default DB path if not passed in switches */
	if(db == NULL && (db_path = get_db_path()) && sqlite3_open(db_path, &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}
	if(db_path) {
		free(db_path);
	}

	if(ownMode) {
		sprintf(sql, "SELECT version,user_owns FROM packages WHERE package='%s';", package);
		if(sqlite3_exec(db, sql, print_o_results, NULL, NULL) != 0) {
			fprintf(stderr, "Malformed query (The specified database may not exist).\n");
			puts(sql);
			exit(EXIT_FAILURE);
		}
	} else {
		if(status == STATUS_NOT_SET || status == UP_TO_DATE) {
			sprintf(sql,"SELECT status FROM packages WHERE package='%s';", package);
			if(sqlite3_exec(db, sql, print_results, &status, NULL) != 0) {
				fprintf(stderr, "Malformed query (The specified database may not exist).\n");
				exit(EXIT_FAILURE);
			}
		}
		if(status != STATUS_NOT_SET) {
			sprintf(sql,"UPDATE packages SET status=%d WHERE package='%s';", status, package);
			if(sqlite3_exec(db, sql, NULL, NULL, NULL) != 0) {
				fprintf(stderr, "Malformed query (The specified database may not exist).\n");
				exit(EXIT_FAILURE);
			}
			printf("%d\n", status);
		}
	}

	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
