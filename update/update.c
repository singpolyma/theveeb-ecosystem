#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef EXIT_SUCCESS
	#define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
	#define EXIT_FAILURE -1
#endif

/* Need somewhere to store data as we parse,
 * because order is not guarenteed */
struct Package {
	/* These sizes are a bit arbitrary,
	 * they seem to be big enough
	 * for data found in the wild, with
	 * some breathing room */
	char package       [  50];
	char version       [  50];
	char section       [  50];
	char md5           [  32];
	char maintainer    [ 100];
	char remote_path   [ 255];
	char homepage      [ 255];
	char description   [1000];
	int installed_size       ;
	int size                 ;
};

int main(int argc, char ** argv) {
	char line[200];
	char * sep;
	FILE * fh;
	struct Package current = {"","","","","","","","",0,0};
	int doing_description = 0;

	/* Read it from a file... do network acces later */
	fh = fopen("Packages","r");

	/* Loop over lines from stream */
	while(fgets(line, sizeof(line), fh)) {
		/* Blank line means end of this package definition */
		if(line[0] == '\n') {
			puts(current.package); /* Print some stuff */
			puts(current.version);
			puts(current.description);
			puts("---");
			doing_description = 0; /* Reset things */
			memset(&current, 0, sizeof(current));
		} else {
			/* Chomp */
			if((sep = strchr(line, '\n'))) {
				*sep = '\0';
			}
			/* Description spans multiple lines at the end, concat stuff */
			if(doing_description) {
				strncat(current.description, "\n", sizeof(current.description));
				strncat(current.description, line, sizeof(current.description));
			} else {
				/* Split on colon */
				if((sep = strchr(line, ':'))) {
					*sep = '\0';
					/* Skip over the space too */
					sep = sep + 2;
					/* If we haven't seen the field yet, do a string compare to see if
					 * this is it. Copu remainder of line into struct */
					if(       current.package[0]      == '\0' && strcmp(line, "Package")        == 0) {
						strncpy(current.package,     sep, sizeof(current.package));
					} else if(current.version[0]      == '\0' && strcmp(line, "Version")        == 0) {
						strncpy(current.version,     sep, sizeof(current.version));
					} else if(current.section[0]      == '\0' && strcmp(line, "Section")        == 0) {
						strncpy(current.section,     sep, sizeof(current.section));
					} else if(current.md5[0]          == '\0' && strcmp(line, "MD5sum")         == 0) {
						strncpy(current.md5,         sep, sizeof(current.md5));
					} else if(current.maintainer[0]   == '\0' && strcmp(line, "Maintainer")     == 0) {
						strncpy(current.maintainer,  sep, sizeof(current.maintainer));
					} else if(current.remote_path[0]  == '\0' && strcmp(line, "Filename")       == 0) {
						strncpy(current.remote_path, sep, sizeof(current.remote_path));
					} else if(current.homepage        == '\0' && strcmp(line, "Homepage")       == 0) {
						strncpy(current.homepage,    sep, sizeof(current.homepage));
					} else if(current.installed_size  ==   0  && strcmp(line, "Installed-Size") == 0) {
						current.installed_size = atoi(sep);
					} else if(current.size            ==   0  && strcmp(line, "Size")           == 0) {
						current.size = atoi(sep);
					} else if(                                   strcmp(line, "Description")    == 0) {
						strncpy(current.description, sep, sizeof(current.description));
						doing_description = 1;
					}
				}
			} /* if doing_description */
		} /* if line[0] == '\n' */
	} /* while */

	fclose(fh);
	exit(EXIT_SUCCESS);
}
