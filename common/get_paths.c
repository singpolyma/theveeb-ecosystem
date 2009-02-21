#include "get_paths.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* malloc or fail */
void *xmalloc(size_t size, const char *caller) {
	void *thing;
	thing = malloc(size);
	if(!thing) {
		perror(caller);
		exit(EXIT_FAILURE);
	}
	return thing;
}

char *xstrdup(const char *str, const char *caller) {
	char *out;
	out = xmalloc( (strlen(str) + 1) * sizeof(*out), caller);
	strcpy(out, str);
	return out;
}

char *get_home() {
	char *home;
	char *path;
	char *other;
#if ! defined(_WIN32) && ! defined(__WIN32__)
	if((path = getenv("HOME")) && path[0] != '\0') {
		return xstrdup(path, "get_home: xstrdup");
	}
#endif
	if((path = getenv("USERPROFILE")) && path[0] != '\0') {
		return xstrdup(path, "get_home: xstrdup");
	}
	if((path = getenv("HOMEDRIVE")) && path[0] != '\0') {
		if((other = getenv("HOMEPATH")) && other[0] != '\0') {
			home = xmalloc( (strlen(path) + strlen(other) + 1) * sizeof(*home), "get_home: malloc" );
			strcpy(home, path);
			strcat(home, other);
			return home;
		}
	}
	return NULL;
}

char *get_db_path() {
	char *path;
	FILE *fp;
	if((path = getenv("TVEDB")) && path[0] != '\0') {
		return xstrdup(path, "get_db_path: xstrdup");
	}
	if((path = get_home())) {
		path = realloc(path, (strlen(path) + 8 + 1) * sizeof(*path));
		if(!path) {
			perror("get_db_path: realloc");
			exit(EXIT_FAILURE);
		}
		strcat(path, "/.tve.db");
		fp = fopen(path, "r+b");
		if(fp) {
			fclose(fp);
			return path;
		}
	}
	return xstrdup(TVEDB, "get_db_path: xstrdup");
}

