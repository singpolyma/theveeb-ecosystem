#ifndef H_VERSION_COMPARE
#define H_VERSION_COMPARE

/* Compare version strings in "major.minor[.sub...]" format.
   Any sequence of non-digits is considered a delimiter; the exact
   contents of delimiters are ignored.
   If one version is a proper prefix of the other, the longer one
   is considered a higher version.
*/
int version_compare(const char * a, const char * b);

/* A wrapper around version_compare suitable for passing to qsort and
   bsearch.
   (This is for sorting pointers to version strings, not the version
   strings themselves.  See <http://www.c-faq.com/lib/qsort1.html>
   for details.).
*/
int compar_version(const void *va,const void *vb);

#endif	/*H_VERSION_COMPARE #include guard*/
