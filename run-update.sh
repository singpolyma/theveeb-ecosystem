#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

if [ -x "`dirname "$0"`/update/update" ]; then
	UPDATE="`dirname "$0"`/update/update"
elif cmdexists tve-update; then
	UPDATE="tve-update"
else
	echo "tve-update not found" 1>&2
	exit 1
fi

if [ -x "`dirname "$0"`/getrepo.sh" ]; then
	"`dirname "$0"`/getrepo.sh" | "$UPDATE"
elif cmdexists tve-getrepo; then
	tve-getrepo | "$UPDATE"
else
	echo "tve-getrepo not found" 1>&2
	exit 1
fi

BASEURL="http://pkgs.theveeb.com" # XXX: Should this be an argument?

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

# URL to fetch
URL="http://theveeb.com/users/me?packages"

TOKENS="`getTVETokens "$BASEURL"`"
REQUEST="`getTVEAuthRequest "$TOKENS" "$URL"`"
net2stdout 'Accept: text/plain' "$REQUEST" | "$UPDATE" -c
