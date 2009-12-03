#include <stdio.h>
#include <stdlib.h>
#include <string.h>
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

/* Need somewhere to store data as we parse,
 * because order is not guarenteed */
struct Package {
	char package       [  50]; /* In Ubuntu, largest is 41 */
	char name          [  50]; /* Human readable name, size is similar to package */
	char category      [  50]; /* Plenty large */
	char version       [  50]; /* Plenty large */
	char section       [  50]; /* Plenty large */
	char md5           [  33]; /* MD5s are 32 characters */
	char maintainer    [ 100]; /* In Ubuntu, largest is 78 */
	char *baseurl;
	char path          [ 256]; /* In Ubuntu, largest subpath is 106 */
	char homepage      [ 256]; /* URLs are specced to a max length of 255 */
	char description   [3000]; /* In Ubuntu, lagest is > 20000, way too rediculous. Most are < 3000 */
	char user_owns     [  50];
	int rating               ;
	int user_rating          ;
	int price                ;
	int installed_size       ;
	int size                 ;
};
struct Package const blank_package = {"","","","","","","","","","","","",0,0,0,0,0};

static int print_sql = 0;

/* Cat src onto dst, double single quote (') characters,
 * prefix and postfix with single quote and, optionally, append
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
	if(print_sql) {
		puts(sql);
	} else {
		if(sqlite3_exec(db, sql, NULL, NULL, NULL) != 0) {
			fprintf(stderr, "%s\n", sqlite3_errmsg(db));
			exit(EXIT_FAILURE);
		}
	}
}

/* Parse the Depends: line for a single package */
void parse_depends(sqlite3 * db, char * package, char * sep) {
	char * endcomma;
	char sql[200];
	sep = strtok(sep, " (");

	if((endcomma = strchr(sep, ','))) {
		*endcomma = '\0';
		strncpy(sql,"INSERT INTO depends (package,depend,version) VALUES (",sizeof(sql)-1);
		quotecat(sql, package, sizeof(sql), 1);
		quotecat(sql, sep, sizeof(sql), 1);
		strncat(sql, "'');", sizeof(sql)-1);
		safe_execute(db, sql);
	} else {
		strncpy(sql,"INSERT INTO depends (package,depend,version) VALUES (",sizeof(sql)-1);
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
			strncpy(sql,"INSERT INTO depends (package,depend,version) VALUES (",sizeof(sql)-1);
			quotecat(sql, package, sizeof(sql), 1);
			quotecat(sql, sep, sizeof(sql), 1);
			strncat(sql, "'');", sizeof(sql)-1);
			safe_execute(db, sql);
		} else {
			strncpy(sql,"INSERT INTO depends (package,depend,version) VALUES (",sizeof(sql)-1);
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
	strncpy(sql,"INSERT INTO packages (package,name,category,version,user_owns,section,md5,maintainer,baseurl,path,homepage,description,rating,user_rating,price,installed_size,size) VALUES (",size);
	quotecat(sql, current->package,     size, 1);
	quotecat(sql, current->name,        size, 1);
	quotecat(sql, current->category,    size, 1);
	quotecat(sql, current->version,     size, 1);
	quotecat(sql, current->user_owns,   size, 1);
	quotecat(sql, current->section,     size, 1);
	quotecat(sql, current->md5,         size, 1);
	quotecat(sql, current->maintainer,  size, 1);
	quotecat(sql, current->baseurl, size, 1);
	quotecat(sql, current->path, size, 1);
	quotecat(sql, current->homepage,    size, 1);
	quotecat(sql, current->description, size, 1);
	sprintf(sql, "%s%d,%d,%d,%d,%d);", sql, current->rating, current->user_rating, current->price, current->installed_size, current->size);
}

/* Generate SQL statement to update a package */

#define UPDATE_SQL_FOR(field) do { \
		if(current->field[0] != '\0') { \
			strncat (sql, #field"=",         size); \
			quotecat(sql, current->field,        size, 1); \
		} \
	} while(0)

void package_update_sql(struct Package * current, char * sql, size_t size) {
	strncpy (sql, "UPDATE packages SET ", size);
	UPDATE_SQL_FOR(name);
	UPDATE_SQL_FOR(category);
	UPDATE_SQL_FOR(version);
	UPDATE_SQL_FOR(user_owns);
	UPDATE_SQL_FOR(section);
	UPDATE_SQL_FOR(md5);
	UPDATE_SQL_FOR(maintainer);
	UPDATE_SQL_FOR(baseurl);
	UPDATE_SQL_FOR(path);
	UPDATE_SQL_FOR(homepage);
	UPDATE_SQL_FOR(description);
	if(current->rating > 0) {
		sprintf(sql, "%srating=%d,", sql, current->rating);
	}
	if(current->user_rating > 0) {
		sprintf(sql, "%suser_rating=%d,", sql, current->user_rating);
	}
	if(current->price > 0) {
		sprintf(sql, "%sprice=%d,", sql, current->price);
	}
	if(current->size > 0) {
		sprintf(sql, "%ssize=%d,", sql, current->size);
	}
	if(current->installed_size > 0) {
		sprintf(sql, "%sinstalled_size=%d,", sql, current->installed_size);
	}
	sql[strlen(sql)-1] = '\0'; /* chomp final , */
	strncat (sql, " WHERE package=",  size);
	quotecat(sql, current->package,     size, 0);
	strncat (sql, ";",             size);
}

/* Display usage message */
void help() {
	puts(
"create/update package database\n"
"Usage: update [OPTION] < [FILE] \n"
"   FILE            Metadata file to read\n"
"   -h              help menu (this screen)\n"
"   -d[path]        path to database file\n"
"   -c              chained call (don't erase or vacuum)\n"
"   -s              print SQL statements instead of executing them\n"
	);
	exit(EXIT_FAILURE);
}

int main(int argc, char ** argv) {
	char * sep;
	sqlite3 * db = NULL;
	struct Package current = blank_package;
	char baseurl[256] = "";
	char line[sizeof(current.homepage)]; /* No line will be larger than the largest field */
	int code;
	int chained_call = 0;
	char * db_path = NULL;
	/* NOTE: If Package ever contains varible fields, this must be changed */
	char sql[sizeof(current) + 8*3*sizeof(char) + 137*sizeof(char) + 256*sizeof(char)];

	while((code = getopt(argc, argv, "schd:")) != -1) {
		switch(code) {
			case 's':
				if(db != NULL) {
					fputs("-d and -s are mutually exclusive\n", stderr);
					exit(EXIT_FAILURE);
				}
				print_sql = 1;
				break;
			case 'c':
				chained_call = 1;
				break;
			case 'h':
				help();
				break;
			case 'd':
				if(print_sql) {
					fputs("-d and -s are mutually exclusive\n", stderr);
					exit(EXIT_FAILURE);
				}
				if(sqlite3_open(optarg, &db) != 0) {
					fprintf(stderr, "%s\n", sqlite3_errmsg(db));
					exit(EXIT_FAILURE);
				}
				break;
			default:
				help();
		}
	}

	/* Open database */
	if(!print_sql && db == NULL && (db_path = get_db_path()) && sqlite3_open(db_path, &db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}
	if(db_path) {
		free(db_path);
	}

	/* Do everything as one transaction. Many times faster */
	safe_execute(db, "BEGIN TRANSACTION;");

	/* Create tables if they do not exist */
	safe_execute(db, "CREATE TABLE IF NOT EXISTS packages " \
	                 "(package TEXT PRIMARY KEY, name TEXT, version TEXT," \
	                 "maintainer TEXT, installed_size INTEGER, size INTEGER," \
	                 "homepage TEXT, section TEXT, category TEXT, baseurl TEXT,"\
	                 "path TEXT, md5 TEXT, description TEXT, user_rating INTEGER,"\
	                 "user_owns TEXT, status INTEGER, rating INTEGER, price INTEGER);" \
	                 "CREATE TABLE IF NOT EXISTS virtual_packages (package TEXT PRIMARY KEY, is_really TEXT);" \
	                 "CREATE TABLE IF NOT EXISTS depends (package TEXT, depend TEXT, version TEXT);"
	            );

	if(!chained_call) {
		safe_execute(db, "DELETE FROM virtual_packages;");
		safe_execute(db, "DELETE FROM depends;");
	}

	/* Loop over lines from stream */
	code = 0;
	while(fgets(line, sizeof(line), stdin)) {
		if(line[0] == '#') {
			/* Chomp */
			if((sep = strchr(line, '\n'))) {
				*sep = '\0';
			}
			strncpy(baseurl, line + 1, sizeof(baseurl)-1);
		/* Blank line means end of this package definition */
		} else if(line[0] == '\n') {
			current.baseurl = baseurl;
			if(current.package[0] != '\0') {
				package_insert_sql(&current, sql, sizeof(sql));

				if(print_sql) {
					puts(sql);
				} else {
					if((code = sqlite3_exec(db, sql, NULL, NULL, NULL)) != 0) {
						if(code == SQLITE_CONSTRAINT) {
							package_update_sql(&current, sql, sizeof(sql));
							safe_execute(db, sql);
						} else {
							fprintf(stderr, "%s\n", sqlite3_errmsg(db));
							exit(EXIT_FAILURE);
						}
					}
				}
			}

			/* Reset things */
			code = 0;
			current = blank_package;
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
					} else if(current.name[0]         == '\0' && strcmp(line, "Name")           == 0) {
						strncpy(current.name,        sep, sizeof(current.name)-1);
					} else if(current.category[0]     == '\0' && strcmp(line, "Category")       == 0) {
						strncpy(current.category,    sep, sizeof(current.category)-1);
					} else if(current.version[0]      == '\0' && strcmp(line, "Version")        == 0) {
						strncpy(current.version,     sep, sizeof(current.version)-1);
					} else if(current.user_owns[0]    == '\0' && strcmp(line, "UserOwns")       == 0) {
						strncpy(current.user_owns,   sep, sizeof(current.user_owns)-1);
					} else if(current.section[0]      == '\0' && strcmp(line, "Section")        == 0) {
						strncpy(current.section,     sep, sizeof(current.section)-1);
					} else if(current.md5[0]          == '\0' && strcmp(line, "MD5sum")         == 0) {
						strncpy(current.md5,         sep, sizeof(current.md5)-1);
					} else if(current.maintainer[0]   == '\0' && strcmp(line, "Maintainer")     == 0) {
						strncpy(current.maintainer,  sep, sizeof(current.maintainer)-1);
					} else if(current.path[0]         == '\0' && strcmp(line, "Filename")       == 0) {
						strncat(current.path, sep,     sizeof(current.path)-1);
					} else if(current.homepage        == '\0' && strcmp(line, "Homepage")       == 0) {
						strncpy(current.homepage,    sep, sizeof(current.homepage)-1);
					} else if(current.rating          ==   0  && strcmp(line, "Rating")         == 0) {
						current.rating = atoi(sep);
					} else if(current.user_rating     ==   0  && strcmp(line, "UserRating")     == 0) {
						current.user_rating = atoi(sep);
					} else if(current.price          ==   0  && strcmp(line, "Price")           == 0) {
						current.price = atoi(sep);
					} else if(current.installed_size  ==   0  && strcmp(line, "Installed-Size") == 0) {
						current.installed_size = atoi(sep);
					} else if(current.size            ==   0  && strcmp(line, "Size")           == 0) {
						current.size = atoi(sep);
					} else if(                                   strcmp(line, "Provides")       == 0) {
						sep = strtok(sep, ", ");
						sql[0] = '\0';
						strncpy(sql, "INSERT INTO virtual_packages (package, is_really) VALUES(", sizeof(sql));
						quotecat(sql, sep, sizeof(sql), 1);
						quotecat(sql, current.package, sizeof(sql), 0);
						strncat(sql, ");", sizeof(sql)-1);
						safe_execute(db, sql);
						while((sep = strtok(NULL, ", ")) != NULL) {
							sql[0] = '\0';
							strncpy(sql, "INSERT INTO virtual_packages (package, is_really) VALUES(", sizeof(sql));
							quotecat(sql, sep, sizeof(sql), 1);
							quotecat(sql, current.package, sizeof(sql), 0);
							strncat(sql, ");", sizeof(sql)-1);
							safe_execute(db, sql);
						}
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
	if(!chained_call) {
		safe_execute(db, "DELETE FROM packages WHERE package='';");
		safe_execute(db, "VACUUM;");
	}

	/* Close database */
	if(db != NULL && sqlite3_close(db) != 0) {
		fprintf(stderr, "%s\n", sqlite3_errmsg(db));
		exit(EXIT_FAILURE);
	}

	exit(EXIT_SUCCESS);
}
