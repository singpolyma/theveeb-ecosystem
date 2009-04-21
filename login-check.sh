#!/bin/sh

. ./setup.sh

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

TOKEN="`cut -d' ' -f1 < "$OAUTHTOKENS"`"
SECRET="`cut -d' ' -f2 < "$OAUTHTOKENS"`"

REQUEST="`oauthsign -c key123 -C sekret -t "$TOKEN" -T "$SECRET" http://singpolyma.net/theveeb/api/nickname.cgi`"
NICK="`net2stdout "$REQUEST"`"
if [ $? -ne 0 ]; then
	echo "Not properly logged in." 1>&2
	exit 2
fi

echo "Logged in."
