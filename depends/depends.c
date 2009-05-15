#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlite3.h>
#include "version_compare.h"
#include "common/get_paths.h"

#if defined(_WIN32) || defined(__WIN32__)
	#include "common/getopt.h"
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
"get package dependencies\n"
"Usage: depends [OPTION] [PACKAGE]\n"
"   -h              this usage message\n"
"   -d[path]        path to database file\n"
	);
	exit(EXIT_FAILURE);
}

/* Globals and utility functions to hold the list of packages 
 * that have already been printed
 */
char **printed_packages = NULL;
int printed_packages_len = 0;
int printed_packages_size = 0;

void printed_package(char *package) {
	if(printed_packages_size == printed_packages_len) {
		printed_packages_size = (printed_packages_size+1)*2;
		printed_packages = realloc(printed_packages, printed_packages_size * sizeof(*printed_packages));
		if(!printed_packages) {
			perror("printed_package");
			exit(EXIT_FAILURE);
		}
	}
	printed_packages[printed_packages_len] = malloc(strlen(package)+1);
	strcpy(printed_packages[printed_packages_len], package);
	printed_packages_len++;
}

int did_print_package(char *package) {
	int i;
	for(i = 0; i < printed_packages_len; i++) {
		if(strcmp(printed_packages[i], package) == 0) {
			return 1;
		}
	}
	return 0;
}

/* This function acts as a SQL query callback for print_results
 * It takes the two values for the row (status, version) and cats 
 * them together into ptr.
 * This creates a string that looks like: I1.2.0
 */
int status_version(void *ptr, int field_count, char **row, char **fields) {
	char *str = ptr;
	(void)fields;
	str[0] = '\0';
	if(row[0]) {
		strcpy(str, row[0]);
	} else {
		str[0] = '0';
		str[1] = '\0';
	}
	/* Allows this function to work if SELECT only got one column */
	if(field_count > 1) {
		if(row[1]) {
			strcat(str, row[1]);
		}
	}
	return 0;
}

/* So they can call each other */
void print_depends(sqlite3 *db, char *package);

/* Print out the dependencies that haven't yet been printed.
 * Add them to the list of ones that have been printed.
 * Don't print packages that are installed and up to date
 */
int print_results(void *db, int field_count, char **row, char **fields) {
	char status[112] = "SELECT status,version FROM packages WHERE package='";
	char virtual[107] = "SELECT is_really FROM virtual_packages WHERE package='";
	(void)field_count;
	(void)fields;
	if(!did_print_package(row[0])) {
		strcat(status, row[0]);
		strcat(status, "' LIMIT 1;");
		if(sqlite3_exec((sqlite3*)db, status, &status_version, status, NULL) != 0) {
			fprintf(stderr, "Malformed query (or the specified database may not exist).\n");
			exit(EXIT_FAILURE);
		}
		if(status[0] == 'S') {/* No record was found, check virtual_packages */
			strcat(virtual, row[0]);
			strcat(virtual, "' LIMIT 1;");
			if(sqlite3_exec((sqlite3*)db, virtual, &status_version, virtual, NULL) != 0) {
				fprintf(stderr, "Malformed query (or the specified database may not exist).\n");
				exit(EXIT_FAILURE);
			}
			if(virtual[0] != 'S' && virtual[0] != '0') { /* Found something */
				status[0] = '\0';
				strcpy(status, "SELECT status,version FROM packages WHERE package='");
				strcat(status, virtual);
				strcat(status, "' LIMIT 1;");
				if(sqlite3_exec((sqlite3*)db, status, &status_version, status, NULL) != 0) {
					fprintf(stderr, "Malformed query (or the specified database may not exist).\n");
					exit(EXIT_FAILURE);
				}
			}
		}
		if(status[0] == 'S') {/* No record was found, external dependency */
			printf("E %s %s\n", row[0], row[1]);
		} else {
			if(version_compare(status, row[1]) <= 0) {
				/* Version available is high enough */
				if(status[0] != '1' && status[0] != '2') {
					/* If the package is not already installed at the newest version
					 * then this needs to be installed as an internal dependency */
					printf("I %s %s\n", row[0], row[1]);
				}
			} else {
				/* If we don't have a high enough version, 
				 * also treat this as an external dependency */
				printf("E %s %s\n", row[0], row[1]);
			}
		}
		printed_package(row[0]);
		print_depends((sqlite3*)db, row[0]);
	}
	return 0;
}

/* Function that gets the list of dependencies for a package 
 * and has the data passed to print_results
 */
void print_depends(sqlite3 *db, char *package) {
	char sql[103] = "SELECT depend,version FROM depends WHERE package='";
	if(strlen(package) > 50) {
		fprintf(stderr, "Package name too long.");
		exit(EXIT_FAILURE);
	}
	strcat(sql,package);
	strcat(sql,"';");
	if(sqlite3_exec(db, sql, &print_results, db, NULL) != 0) {
		fprintf(stderr, "Malformed query (or the specified database may not exist).\n");
		exit(EXIT_FAILURE);
	}
}

int main (int argc, char ** argv) {
	sqlite3 * db = NULL;
	char * package = NULL;
	char * db_path = NULL;
	int c;

	while((c = getopt(argc, argv, "-hd:")) != -1) {
		switch(c) {
			case 'd': /* Specify database */
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case '\1': /* Search query */
				package = optarg;
				break;
			case 'h': /* Usage message and exit */
			default:
				help();
		}
	}

	if(!package && optind < argc) {
		package = argv[optind];
		if(package[0] == '\0' || package[0] == '-') {
			package = NULL;
		}
	}

	if(!package) {
		help();
	}

	if(db == NULL && (db_path = get_db_path()) && sqlite3_open(db_path, &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}
	if(db_path) {
		free(db_path);
	}

	print_depends(db, package);

	if(printed_packages) {
		int i;
		for(i = 0; i < printed_packages_len; i++) {
			free(printed_packages[i]);
		}
		free(printed_packages);
	}

	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
