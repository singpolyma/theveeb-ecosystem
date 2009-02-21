#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlite3.h>
#include "common/get_paths.h"

#if defined(_WIN32) || defined(__WIN32__)
	#include "common/getopt.h"
#else
	#include <unistd.h>
	int getopt(int argc, char * const argv[], const char *optstring);
	extern char *optarg;
	extern int optind, opterr, optopt;
#endif

/* Print usage message */
void help() {
	puts("search for packages");
	puts("Usage: search [OPTION] [QUERY]");
	puts("   QUERY           Pattern to search for");
	puts("   -h              help menu (this screen)");
	puts("   -l              list (search package names only)");
	puts("   -v              verbose (more complete output)");
	puts("   -i[category]    category/section to restrict search to");
	puts("   -x[category]    category/section to exclude from results");
	puts("   -s[field]       field to sort by: package, version, description, or rating");
	puts("   -d[path]        path to database file");
}

/* Callback for query: print row */
int print_results(void * dummy, int field_count, char ** row, char ** fields) {
	char status = ' ';
	char * end;

	(void)dummy;
	(void)field_count;
	(void)fields;

	end = strchr(row[3], '\n');
	if(end) {
		*end = '\0';
	}
	if(row[0]) {
		int status_val=strtol(row[0],&end,10);
		if(*end) {
			fprintf(stderr,"Database interface error: Invalid integer!\n");
			abort();
		}
		/*If we extend the negative end of the status value range,
		    both the offset here and the status string in the
		    "else" branch will need to be updated.   --DV
		*/
		status_val++;
		if(status_val < 0 || status_val > 3) {
			status='?';
		} else {
			/*Array indexing magic!*/
			status="U ID"[status_val];
		}
	}
	printf("%c %-20s %-10s %s\n", status, row[1], row[2], row[3]);
	return 0;
}

/* Callback for query: print row (verbose) */
int print_results_verbose(void * dummy, int field_count, char ** row, char ** fields) {
	int status_val;

	(void)dummy;
	(void)field_count;
	(void)fields;

	printf("Package: %s\n", row[1]);

	if(row[0]) {
		char *end;
		status_val=strtol(row[0],&end,10);
		if(*end) {
			fprintf(stderr,"Database interface error: Invalid integer!\n");
			abort();
		}
	} else {
		status_val=0;
	}
	switch(status_val) {
		case 1: puts("Status: installed"); break;
		case 2: puts("Status: installed as dependency"); break;
		case -1: puts("Status: update available"); break;
		case 0: puts("Status: not installed"); break;
	}

	printf("Version: %s\n", row[2]);
	printf("Download: %s\n", row[4]);
	printf("Description: %s\n", row[3]);
	puts("");
	return 0;
}

int check_order_by(const char *s) {
	size_t i;
	char *valid[]={
		"package",
		"version",
		"description",
		"rating"
	};
	size_t num=sizeof valid / sizeof valid[0];

	for(i=0;i<num;i++)
		if(strcmp(s,valid[i]) == 0)
			return 1;
	return 0;
}

int main (int argc, char ** argv) {
	sqlite3 * db = NULL;
	char sql[250] = "";
	char * query = NULL;
	char * include_cats = NULL;
	char * exclude_cats = NULL;
	char * order_by = "package";
	char * db_path = NULL;
	int (*output_callback)(void *,int,char **,char **)=print_results;
	int c;
	int search_description=1;

	while((c = getopt(argc, argv, "-lvhi:x:s:d:")) != -1) {
		switch(c) {
			case 'l': /* Search package names only */
				search_description=0;
				break;
			case 'v':
				output_callback=print_results_verbose;
				break;
			case 'i':
				include_cats = optarg;
				break;
			case 'x':
				exclude_cats = optarg;
				break;
			case 's':
				if(check_order_by(optarg)) {
					order_by = optarg;
				} else {
					fprintf(stderr,"Invalid sort field: `%s'\n",optarg);
					help();
					exit(EXIT_FAILURE);
				}
				break;
			case 'd': /* Specify database */
				/*XXX We might want to sanity-check that the database does
				    actually exist.   --DV
				*/
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case '\1': /* Search query */
				/*XXX Not a very sensible way to handle possible multiple
				    search query arguments.   --DV
				*/
				query = optarg;
				break;
			case 'h': /* Usage message and exit */
				help();
				exit(EXIT_SUCCESS);
			default:  /* Unrecognized option */
				help();
				exit(EXIT_FAILURE);
		}
	}

	if(!query && optind < argc) {
		query = argv[optind];
		if(query[0] == '\0' || query[0] == '-') {
			query = NULL;
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
		strcpy(sql, "SELECT status,package,version,description,remote_path FROM packages WHERE 1=1");
	} else {
		if(strchr(query, '\'') != NULL) {
			fprintf(stderr, "Malformed query (single-quote not allowed).\n");
			exit(EXIT_FAILURE);
		}

		/* Static buffers are retarded, block long searches */
		if(strlen(query) > 43) {
			fprintf(stderr,"Your query is too long.  Go beat Stephen with the cluebat.\n");
			exit(EXIT_FAILURE);
		}

		if(search_description) {
			sprintf(sql, "SELECT status,package,version,description,remote_path FROM packages WHERE (package LIKE '%%%s%%' OR description LIKE '%%%s%%')", query, query);
		} else {
			sprintf(sql, "SELECT status,package,version,description,remote_path FROM packages WHERE package LIKE '%%%s%%'", query);
		}
	}

	if(include_cats) {
		strcat(sql, " AND (section='");
		strcat(sql, include_cats);/* FIXME: sanitize, split by comma and support multiple cats */
		strcat(sql, "' OR category='");
		strcat(sql, include_cats);/* FIXME: sanitize, split by comma and support multiple cats */
		strcat(sql, "')");
	}

	if(exclude_cats) {
		strcat(sql, " AND (section!='");
		strcat(sql, exclude_cats);/* FIXME: sanitize, split by comma and support multiple cats */
		strcat(sql, "' AND category!='");
		strcat(sql, exclude_cats);/* FIXME: sanitize, split by comma and support multiple cats */
		strcat(sql, "')");
	}

	strcat(sql, " ORDER BY ");
	strcat(sql, order_by);

	if(sqlite3_exec(db, sql, output_callback, NULL, NULL) != 0) {
		fprintf(stderr, "Malformed query (The specified database may not exist).\n");
		exit(EXIT_FAILURE);
	}

	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
