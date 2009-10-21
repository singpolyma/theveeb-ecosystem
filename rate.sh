#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

BASEURL="http://pkgs.theveeb.com/" # XXX: Should this be an argument?

TOKENS="`getTVETokens "$BASEURL"`"
REQ="`getTVEAuthRequest "$TOKENS" "https://theveeb.com/apps/$1" "PUT" -d "rating=$2"`"

# Use cURL, since wget can't do PUT
# Send parameters in query string for OAuth
curl -X PUT "$REQ"
