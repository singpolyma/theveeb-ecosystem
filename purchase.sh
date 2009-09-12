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
RESPONSE="`curl -sfL -X PURCHASE "$REQUEST"`"
if [ $? -ne 0 ]; then
	echo "$RESPONSE"
	exit 2
fi

echo "$RESPONSE"
