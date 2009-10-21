#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

# Expects app-name -d 'k=v' -d 'k2-v2' NO URL ENCODING

TOKENS="`getTVETokens "$BASEURL"`"
APP="$1"
shift
REQ="`getTVEAuthRequest "$TOKENS" "https://theveeb.com/apps/$APP" "POST" -d 'item=feedback' "$@" | cut -d'?' -f2`"
post2stdout "https://theveeb.com/apps/$APP" "$REQ"
