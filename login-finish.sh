#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

# Verify tokens were passed in
if [ "$#" -eq 2 ]; then
	# We've been passed two tokens
	REQ_TOKEN="$1"
	REQ_SECRET="$2"
elif [ "$#" -eq 1 -a "$1" = "-" ]; then
	# Read tokens from stdin
	TOKEN_IN="`cat`"
	REQ_TOKEN="`echo "$TOKEN_IN" | cut -d ' ' -f 1`"
	REQ_SECRET="`echo "$TOKEN_IN" | cut -d ' ' -f 2`"
else
	# No tokens
	echo "Expected two tokens" 1>&2
	echo "USAGE: login-finish TOKEN SECRET" 1>&2
	echo "   OR  login-finish -" 1>&2
	exit 1
fi

BASEURL="http://pkgs.theveeb.com/" # XXX: Should this be an argument?

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

REQUEST="`oauthsign -c anonymous -C anonymous -t "$REQ_TOKEN" -T "$REQ_SECRET" http://theveeb.com:40703/oauth/access_token`"
TOKENS="`net2stdout "$REQUEST"`"

# Verify the expected output was returned
if [ "`echo $TOKENS | cut -c 1-11`" != "oauth_token" ]; then
	# Request Failed
	echo "Authentication failed on server." 1>&2
	echo "The server could be unreachable, invalid tokens were given to this script, or you could have failed to authorize this application." 1>&2
	exit 1
fi

TOKEN="`echo $TOKENS | sed 's/^oauth_token=\([^&]*\).*/\1/'`"
SECRET="`echo $TOKENS | sed 's/^[^&]*&oauth_token_secret=\(.*\)/\1/'`"

if [ "`whoami`" = "root" ]; then
	TOKENPATH="$TVEROOT/etc/tve-oauth-tokens"
else
	TOKENPATH="$HOME/.tve-oauth-tokens"
fi

if [ -e "$TOKENPATH" -a ! -w "$TOKENPATH" ]; then
	echo "ERROR: $TOKENPATH not writable." 1>&2
	exit 1
fi

echo "$BASEURL $TOKEN $SECRET" > "$TOKENPATH"

# Make sure the tokens have sane permissions
if cmdexists chmod; then
	chmod 0600 "$TOKENPATH"
fi

echo "Authentication Successful"
