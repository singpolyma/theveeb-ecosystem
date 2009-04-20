#!/bin/sh

# Verify tokens were passed in
if [ "$#" -eq 2 ]; then
	# We've been passed two tokens
	REQ_TOKEN="$1"
	REQ_SECRET="$2"
elif [ "$#" -eq 1 -a "$1" == "-" ]; then
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

REQUEST="`oauthsign -c key123 -C sekret -t "$REQ_TOKEN" -T "$REQ_SECRET" http://csclub.uwaterloo.ca:4567/oauth/access_token`"
TOKENS="`$GET "$REQUEST"`"

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

echo "$TOKEN $SECRET" > "$TOKENPATH"

echo "Authentication Successful"
