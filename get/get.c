#include <stdio.h>
#include <stdlib.h>
#include <curl/curl.h>

#ifndef EXIT_SUCCESS
	#define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
	#define EXIT_FAILURE -1
#endif

/* Loop over manually because ptr is not NULL-terminated.
 * WARNING: each element in ptr is size bytes, not guarenteed to be a char. */
size_t print_result(void * ptr, size_t size, size_t nmemb, void * stream) {
	size_t i;
	for(i = 0; i < nmemb; i++) {
		putchar(((char*)ptr)[i]);
	}
	return size * nmemb;
}

int main(int argc, char ** argv) {
	CURL *curl;
	CURLcode code;

	if(argc < 2) {
		fputs("Please specify a URL.\n", stderr);
		exit(EXIT_FAILURE);
	}

	/* Set up cURL */
	if((code = curl_global_init(CURL_GLOBAL_ALL)) != 0) {
		fputs(curl_easy_strerror(code), stderr);
		exit(EXIT_FAILURE);
	}

	/* Create a request with cURL easy */
	if((curl = curl_easy_init())) {

		/* Set options */
		curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 1);
		curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1);
		curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, &print_result);
		curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 GetTest");
		curl_easy_setopt(curl, CURLOPT_URL, argv[1]);

		/* Pass chunks of data from request to WRITIEFUNCTION callback */
		if((code = curl_easy_perform(curl)) != 0) {
			fputs(curl_easy_strerror(code), stderr);
			exit(EXIT_FAILURE);
		}

		/* Be sure you clean up! */
		curl_easy_cleanup(curl);

	} else {
		fputs("Fatal cURL error.\n", stderr);
		exit(EXIT_FAILURE);
	}

	/* Programs that don't output a final newline are annoying */
	putchar('\n');

	exit(EXIT_SUCCESS);
}
