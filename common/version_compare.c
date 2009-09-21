#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "version_compare.h"

int compar_version(const void *va,const void *vb) {
	const char * const *a = va;
	const char * const *b = vb;
	return version_compare(*a, *b);
}

int version_compare(const char * a, const char * b) {
	char *at, *bt;
	int aval, bval;

	a = strpbrk(a, "0123456789");
	b = strpbrk(b, "0123456789");

	while(a && b) {
		aval = strtol(a, &at, 10);
		bval = strtol(b, &bt, 10);

		if(aval != bval) {
			return bval - aval;
		}

		a = strpbrk(at, "0123456789");
		b = strpbrk(bt, "0123456789");
	}

	/* If we fall out of the loop, we've found the end of at least
	   one version string.
	*/
	if(a) {     /*a has an additional sub-version*/
		return -1;
	}
	if(b) {     /*b has an additional sub-version*/
		return 1;
	}

	/* If we get here, we haven't found any differences in versions
	   (except possibly different delimiters, which we ignore)
	*/
	return 0;
}
