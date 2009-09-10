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

REQUEST="`oauthsign -c anonymous -C anonymous -t "$TOKEN" -T "$SECRET" http://theveeb.com/users/me?packages`"
net2stdout 'Accept: text/plain' "$REQUEST" | "$UPDATE" -c
