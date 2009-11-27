#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

# Find the file where OAuth tokens are and get them
OAUTHTOKENS="$HOME/.tve-oauth-tokens"
if [ ! -r "$OAUTHTOKENS" ]; then
	OAUTHTOKENS="$TVEROOT/etc/tve-oauth-tokens"
fi

BASEURL="http://pkgs.theveeb.com" # XXX: Should this be an argument?

DATA="`grep -v "$BASEURL" "$OAUTHTOKENS"`"
if [ -z "$DATA" ]; then
	rm -f "$OAUTHTOKENS"
else
	echo "$DATA" > "$OAUTHTOKENS"
fi

echo "Logout successful."
