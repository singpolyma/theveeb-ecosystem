#ifndef TVEDB
	/* XXX: If this is changed, it has to be changed in gui.tcl */
	#define TVEDB "/var/cache/tve.db"
#endif

#ifndef EXIT_SUCCESS
	#define EXIT_SUCCESS 0
#endif

#ifndef EXIT_FAILURE
	#define EXIT_FAILURE -1
#endif

#ifndef _GET_PATHS_H
	#define _GET_PATHS_H 1

	/* Returns the users home or profile directory, if found.
	 * Returns NULL if no directory could be found.
	 * Does not guarentee the directory exists.
	 * Does require that the caller free the result.
	 */
	char *get_home();

	/* Returns the path to The Veeb Ecosystem cache DB.
	 * Result is a malloc'd string, which the caller must free.
	 * Failure to allocate memory will result in abnormal 
	 *   program termination, using exit()
	 * Returns value of TVEDB macro if nothing else can be found.
	 *   (You may override with -D=\"BLAH\" or similar.)
	 */
	char *get_db_path();

#endif /* _GET_PATHS_H */
