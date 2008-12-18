#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

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

/* Need somewhere to store data as we parse,
 * because order is not guarenteed */
struct Package {
	char package       [  50]; /* In Ubuntu, largest is 41 */
	char version       [  50]; /* Plenty large */
	char section       [  50]; /* Plenty large */
	char md5           [  32]; /* MD5s are 32 characters */
	char maintainer    [ 100]; /* In Ubuntu, largest is 78 */
	char remote_path   [ 255]; /* In Ubuntu, largest subpath is 106 */
	char homepage      [ 255]; /* URLs are specced to a max length of 255 */
	char description   [3000]; /* In Ubuntu, lagest is > 20000, way too rediculous. Most are < 3000 */
	int installed_size      ;
	int size                ;
};

/* Cat src onto dst, double single quote (') characters,
 * prefix and postfix with single quote and, optionally, postpend
 * a comma. Pass the size of dst as n and the function will do
 * bounds-checking, returning -1 if it truncates data. */
int quotecat(char * dst, char * src, size_t n, int comma) {
	size_t i;
	size_t offset = strlen(dst)+1;
	dst[offset-1] = '\'';
	for(i = 0; i < (n-offset-3) && src[i] != '\0'; i++) {
		if(src[i] == '\'') {
			if(offset + i + 2 > n) break;
			dst[offset + i] = src[i];
			offset++;
			dst[offset + i] = '\'';
		} else {
			dst[offset + i] = src[i];
		}
	}
	dst[offset + i] = '\'';
	if(comma) dst[offset + i + 1] = ',';
	dst[offset + i + 2] = '\0';
	if(offset + i + 3 > n) return -1;
	return 0;
}

/* Safely execute a SQL query with no callback */
void safe_execute(sqlite3 * db, char * sql) {
	if(sqlite3_exec(db, sql, NULL, NULL, NULL) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}
}

/* Parse the Depends: line for a single package */
void parse_depends(sqlite3 * db, char * package, char * sep) {
	char * endcomma;
	char sql[200];
	sep = strtok(sep, " (");

	if((endcomma = strchr(sep, ','))) {
		*endcomma = '\0';
		strncpy(sql, "INSERT INTO depends (package, depend, version) VALUES (", sizeof(sql)-1);
		quotecat(sql, package, sizeof(sql), 1);
		quotecat(sql, sep, sizeof(sql), 1);
		strncat(sql, "'');", sizeof(sql)-1);
		safe_execute(db, sql);
	} else {
		strncpy(sql, "INSERT INTO depends (package, depend, version) VALUES (", sizeof(sql)-1);
		quotecat(sql, package, sizeof(sql), 1);
		quotecat(sql, sep, sizeof(sql), 1);
		strtok(NULL, " ");
		if((sep = strtok(NULL, ")")) != NULL) {
			quotecat(sql, sep, sizeof(sql), 0);
			strncat(sql, ");", sizeof(sql)-1);
			safe_execute(db, sql);
			strtok(NULL, " ");
		} else {
			strncat(sql, "'');", sizeof(sql)-1);
			safe_execute(db, sql);
		}
	}
	while(sep != NULL) {
		sep = strtok(NULL, " (");
		if(sep == NULL) break;
		if((endcomma = strchr(sep, ','))) {
			*endcomma = '\0';
			strncpy(sql, "INSERT INTO depends (package, depend, version) VALUES (", sizeof(sql)-1);
			quotecat(sql, package, sizeof(sql), 1);
			quotecat(sql, sep, sizeof(sql), 1);
			strncat(sql, "'');", sizeof(sql)-1);
			safe_execute(db, sql);
		} else {
			strncpy(sql, "INSERT INTO depends (package, depend, version) VALUES (", sizeof(sql)-1);
			quotecat(sql, package, sizeof(sql), 1);
			quotecat(sql, sep, sizeof(sql), 1);
			strtok(NULL, " ");
			if((sep = strtok(NULL, ")"))) {
				quotecat(sql, sep, sizeof(sql), 0);
				strncat(sql, ");", sizeof(sql)-1);
				safe_execute(db, sql);
				sep = strtok(NULL, " ");
			} else {
				strncat(sql, "'');", sizeof(sql)-1);
				safe_execute(db, sql);
			}
		}
	}
}

/* Generate SQL statement to insert a package */
void package_insert_sql(struct Package * current, char * sql, size_t size) {
	strncpy(sql, "INSERT INTO packages (package, version, maintainer, homepage, section, remote_path, md5, description, installed_size, size) VALUES (", size);
	quotecat(sql, current->package,     size, 1);
	quotecat(sql, current->version,     size, 1);
	quotecat(sql, current->maintainer,  size, 1);
	quotecat(sql, current->homepage,    size, 1);
	quotecat(sql, current->section,     size, 1);
	quotecat(sql, current->remote_path, size, 1);
	quotecat(sql, current->md5,         size, 1);
	quotecat(sql, current->description, size, 1);
	sprintf(sql, "%s%d,%d);", sql, current->installed_size, current->size);
}

/* Generate SQL statement to update a package */
void package_update_sql(struct Package * current, char * sql, size_t size) {
	strncpy(sql, "UPDATE packages SET version=", size);
	quotecat(sql, current->version,     size, 1);
	strncat (sql, "maintainer=",   size);
	quotecat(sql, current->maintainer,  size, 1);
	strncat (sql, "homepage=",     size);
	quotecat(sql, current->homepage,    size, 1);
	strncat (sql, "section=",      size);
	quotecat(sql, current->section,     size, 1);
	strncat (sql, "remote_path=",  size);
	quotecat(sql, current->remote_path, size, 1);
	strncat (sql, "md5=",          size);
	quotecat(sql, current->md5,         size, 1);
	strncat (sql, "description=",  size);
	quotecat(sql, current->description, size, 1);
	sprintf(sql, "%sinstalled_size=%d,size=%d WHERE package=", sql, current->installed_size, current->size);
	quotecat(sql, current->package, size, 0);
	strncat (sql, ";",             size);
}

/* Display usage message */
void help() {
	puts("TODO");
	exit(EXIT_FAILURE);
}

int main(int argc, char ** argv) {
	char * sep;
	char * baseurl = NULL;
	sqlite3 * db = NULL;
	struct Package current = {"","","","","","","","",0,0};
	char line[sizeof(current.homepage)]; /* No line will be larger than the largest field */
	int code;
	/* NOTE: If Package ever contains varible fields, this must be changed */
	char sql[sizeof(current) + 8*3*sizeof(char) + 137*sizeof(char)];

	/* TODO: 
	 *       SQL output
	 */

	while((code = getopt(argc, argv, "-lhd:")) != -1) {
		switch(code) {
			case 'h':
				help();
				break;
			case 'd':
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			case '\1':
				baseurl = optarg;
				break;
			default:
				help();
		}
	}

	if(baseurl == NULL) {
		help();
	}

	/* Open database */
	if(db == NULL && sqlite3_open("test.db", &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	/* Do everything as one transaction. Many times faster */
	safe_execute(db, "BEGIN TRANSACTION;");

	/* Create tables if they do not exist */
	safe_execute(db, "CREATE TABLE IF NOT EXISTS packages " \
	                 "(package TEXT PRIMARY KEY, version TEXT, maintainer TEXT," \
	                 " installed_size INTEGER, size INTEGER, homepage TEXT," \
	                 " section TEXT, remote_path TEXT, md5 TEXT, description TEXT," \
	                 " status INTEGER);" \
	                 "CREATE TABLE IF NOT EXISTS depends (package TEXT, depend TEXT, version TEXT);"
	            );

	safe_execute(db, "DELETE FROM depends;");

	/* Loop over lines from stream */
	code = 0;
	while(fgets(line, sizeof(line), stdin)) {
		/* Blank line means end of this package definition */
		if(line[0] == '\n') {
			package_insert_sql(&current, sql, sizeof(sql));

			if((code = sqlite3_exec(db, sql, NULL, NULL, NULL)) != 0) {
				if(code == SQLITE_CONSTRAINT) {
					package_update_sql(&current, sql, sizeof(sql));
					safe_execute(db, sql);
				} else {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
			}

			/* Reset things */
			code = 0;
			memset(&current, 0, sizeof(current));
		} else {
			/* Chomp */
			if((sep = strchr(line, '\n'))) {
				*sep = '\0';
			}
			/* Description spans multiple lines at the end, concat stuff */
			if(code) {
				strncat(current.description, "\n", sizeof(current.description)-1);
				strncat(current.description, line, sizeof(current.description)-1);
			} else {
				/* Split on colon */
				if((sep = strchr(line, ':'))) {
					*sep = '\0';
					/* Skip over the space too */
					sep = sep + 2;
					/* If we haven't seen the field yet, do a string compare to see if
					 * this is it. Copy remainder of line into struct */
					if(       current.package[0]      == '\0' && strcmp(line, "Package")        == 0) {
						strncpy(current.package,     sep, sizeof(current.package)-1);
					} else if(current.version[0]      == '\0' && strcmp(line, "Version")        == 0) {
						strncpy(current.version,     sep, sizeof(current.version)-1);
					} else if(current.section[0]      == '\0' && strcmp(line, "Section")        == 0) {
						strncpy(current.section,     sep, sizeof(current.section)-1);
					} else if(current.md5[0]          == '\0' && strcmp(line, "MD5sum")         == 0) {
						strncpy(current.md5,         sep, sizeof(current.md5)-1);
					} else if(current.maintainer[0]   == '\0' && strcmp(line, "Maintainer")     == 0) {
						strncpy(current.maintainer,  sep, sizeof(current.maintainer)-1);
					} else if(current.remote_path[0]  == '\0' && strcmp(line, "Filename")       == 0) {
						strncpy(current.remote_path, baseurl, sizeof(current.remote_path)-1);
						strncat(current.remote_path, sep,     sizeof(current.remote_path)-1);
					} else if(current.homepage        == '\0' && strcmp(line, "Homepage")       == 0) {
						strncpy(current.homepage,    sep, sizeof(current.homepage)-1);
					} else if(current.installed_size  ==   0  && strcmp(line, "Installed-Size") == 0) {
						current.installed_size = atoi(sep);
					} else if(current.size            ==   0  && strcmp(line, "Size")           == 0) {
						current.size = atoi(sep);
					} else if(                                   strcmp(line, "Depends")        == 0) {
						parse_depends(db, current.package, sep);
					} else if(                                   strcmp(line, "Description")    == 0) {
						strncpy(current.description, sep, sizeof(current.description)-1);
						code = 1;
					}
				}
			} /* if code */
		} /* if line[0] == '\n' */
	} /* while */

	/* End the transaction only when all data has been inserted */
	safe_execute(db, "END TRANSACTION;");

	/* Clean up disk space */
	safe_execute(db, "VACUUM;");

	/* Close database */
	if(sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
