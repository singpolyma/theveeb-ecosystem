#include "md5.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#ifndef EXIT_SUCCESS
	#define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
	#define EXIT_FAILURE -1
#endif

void md5(char * dst, char * src, size_t len) {
	/* dst must be at least 33 */
	/* src can be any length */
	int i;
	int c = 0;
	const char *hexdigits = "0123456789abcdef";
	md5_state_t pms;
	md5_byte_t digest[16];

	/* Initialize the algorithm. */
	md5_init(&pms);

	/* Append a string to the message. */
	md5_append(&pms, (md5_byte_t*)src, len);

	/* Finish the message and return the digest. */
	md5_finish(&pms, digest);

	for(i = 0; i < 16; i++) {
		dst[c++] = hexdigits[digest[i]>>4];
		dst[c++] = hexdigits[digest[i]&0xf];
	}
	dst[c++] = '\0';
}

int main(int argc, char *argv[]) {
	char out[33]; /* MD5 is 32 + \0 */
	char * string = malloc(1*sizeof(*string));
	int bufsize = 1;
	int len = 0;
	int nread = 0;
	if(argc < 2 || (strlen(argv[1]) == 1 && argv[1][0] == '-')) {
		/* Don't treat it as a string, because it may be binary data */
		while((nread = fread(string+len, 1, bufsize-len, stdin)) == (bufsize-len)) { 
			len = bufsize;
			bufsize = 2*(bufsize+1)*sizeof(*string);
			string = realloc(string, bufsize);
			if(!string) {
				fputs("Failed to allocate memory\n", stderr);
				exit(EXIT_FAILURE);
			}
		} 
		len += nread;
	} else {
		string = argv[1];
		len = strlen(string);
	}
	md5(out, string, len);
	printf("%s\n", out);
	exit(EXIT_SUCCESS);
}
