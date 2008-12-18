#include "md5.h"
#include <stdio.h>
#include <string.h>

void md5(char * dst, char * src) {
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
	md5_append(&pms, (md5_byte_t*)src, strlen(src));

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
	if(argc < 2) {
		fputs("You must specify a string to hash.\n", stderr);
		return -1;
	}
	md5(out, argv[1]);
	printf("%s\n", out);
	return 0;
}
