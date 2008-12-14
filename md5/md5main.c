#include "md5.h"
#include <stdio.h>
#include <string.h>

void md5(char * dst, char * string) {
	int i;
	md5_state_t pms;
	md5_byte_t digest[16];

	/* Initialize the algorithm. */
	md5_init(&pms);

	/* Append a string to the message. */
	md5_append(&pms, (md5_byte_t*)string, strlen(string));

	/* Finish the message and return the digest. */
	md5_finish(&pms, digest);

	dst[0] = '\0';
	for(i = 0; i < 16; i++) {
		sprintf(dst, "%s%x", dst, digest[i]);
	}
	
}

int main(int argc, char *argv[]) {
	char out[32];
	if(argc < 2) {
		fputs("You must specify a string to hash.\n", stderr);
		return -1;
	}
	md5(out, argv[1]);
	printf("%s\n", out);
	return 0;
}
