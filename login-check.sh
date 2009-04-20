#!/bin/sh

# Find the network utility
if command -v wget 1>&2; then
	GET="wget -q -O -"
elif command -v curl 1>&2; then
	GET="curl -sfL"
else
	echo "You must have wget or curl installed." 1>&2
	exit 1
fi

# Verify the presence of oauthsign
if ! command -v oauthsign 1>&2; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

# Find the file where OAuth tokens are and get them
OAUTHTOKENS="$HOME/.tve-oauth-tokens"
if [ "`whoami`" = "root" -o ! -r "$OAUTHTOKENS" ]; then
	OAUTHTOKENS="$TVEROOT/etc/tve-oauth-tokens"
fi

if [ ! -r "$OAUTHTOKENS" ]; then
	echo "Not logged in." 1>&2
	exit 2
fi

TOKEN="`cut -d' ' -f1 < "$OAUTHTOKENS"`"
SECRET="`cut -d' ' -f2 < "$OAUTHTOKENS"`"

REQUEST="`oauthsign -c key123 -C sekret -t "$TOKEN" -T "$SECRET" http://singpolyma.net/theveeb/api/nickname.cgi`"
NICK="`$GET "$REQUEST"`"
if [ $? -ne 0 ]; then
	echo "Not properly logged in." 1>&2
	exit 2
fi

echo "Logged in."
