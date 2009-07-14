#!/bin/sh

. ./setup.sh

BASEURL="http://csclub.uwaterloo.ca/~s3weber/apt/" # XXX: Should this be an argument?

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

# Find the file where OAuth tokens are and get them
OAUTHTOKENS="$HOME/.tve-oauth-tokens"
if [ ! -r "$OAUTHTOKENS" ]; then
	OAUTHTOKENS="$TVEROOT/etc/tve-oauth-tokens"
fi

if [ ! -r "$OAUTHTOKENS" ]; then
	echo "Not logged in." 1>&2
	exit 2
fi

TOKEN="`grep "$BASEURL" < "$OAUTHTOKENS" | cut -d' ' -f2`"
SECRET="`grep "$BASEURL" < "$OAUTHTOKENS" | cut -d' ' -f3`"

REQUEST="`oauthsign -c anonymous -C anonymous -t "$TOKEN" -T "$SECRET" http://theveeb.com/users/me`"
T="`net2stdout "$REQUEST"`"
if [ $? -ne 0 ]; then
	echo "Not properly logged in." 1>&2
	exit 2
fi

echo "Logged in."
