#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

BASEURL="http://pkgs.theveeb.com/" # XXX: Should this be an argument?

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

PACKAGE="$1"
URL="https://theveeb.com/apps/$PACKAGE"

# Find the file where OAuth tokens are and get them
TOKENS="`getTVETokens "$BASEURL"`"
REQUEST="`getTVEAuthRequest "$TOKENS" "$URL" "PURCHASE"`"

# Make the request
# (The -w means that after the body it will output the HTTP Response Code)
RESPONSE="`curl -sL -X PURCHASE -w '%{http_code}' "$REQUEST"`"
# Pull out the Response Code
R_CODE="`echo "$RESPONSE" | tail -n 1`"
# And take the Reponse Code off the Reponse
RESPONSE="`echo "$RESPONSE" | sed '$d'`"

if [ "$R_CODE" != 200 ]; then
	echo "$RESPONSE"
	exit 2
fi

echo "$RESPONSE"
