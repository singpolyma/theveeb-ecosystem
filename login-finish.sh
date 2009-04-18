#!/bin/sh

# Verify tokens were passed in
if [ "$#" -ne 2 ]; then
	echo "Expected two tokens" 1>&2
	echo "USAGE: login-finish TOKEN SECRET" 1>&2
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

REQUEST="`oauthsign -c key123 -C sekret -t "$1" -T "$2" http://csclub.uwaterloo.ca:4567/oauth/access_token`"
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

echo "$TOKEN $SECRET" > "$HOME/.tve-oauth-tokens"
