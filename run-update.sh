#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

UPDATE="`findTVEbinary update`"
GETREPO="`findTVEscript getrepo`"

# Catch error code and exit
if ! DATA="`sh "$GETREPO"`

"; then
	exit 1
fi
echo "$DATA" | "$UPDATE" # Windows likes it better this way
if [ $? -ne 0 ]; then
	exit 1
fi

BASEURL="http://pkgs.theveeb.com" # XXX: Should this be an argument?

# URL to fetch
URL="https://theveeb.com/users/me?packages"

TOKENS="`getTVETokens "$BASEURL"`"
REQUEST="`getTVEAuthRequest "$TOKENS" "$URL"`"
net2stdout 'Accept: text/plain' "$REQUEST" | "$UPDATE" -c
