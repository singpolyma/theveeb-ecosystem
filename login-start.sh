#!/bin/sh

. ./setup.sh

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

# Find the command to open a URL, if there is one
OPEN=""
if cmdexists xdg-open; then
	OPEN="xdg-open"
elif cmdexists open; then
	OPEN="open"
elif cmdexists cmd; then
	OPEN="cmd /c start"
fi

REQUEST="`oauthsign -c anonymous -C anonymous http://csclub.uwaterloo.ca:4567/oauth/request_token`"
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

# This is the url to send the user to
URL="http://singpolyma.net/theveeb/authorize.php?oauth_token=$TOKEN&xoauth_consumer_label=The+Veeb+Ecosystem's+Official+Client"

# Output the tokens
echo "$TOKEN $SECRET"

if [ -n "$OPEN" ]; then
	# If we can open urls for the user, do so
	$OPEN "$URL" &
else
	# If we can't, output the url they should go to on their own
	echo "Go to \"$URL\" in a browser to continue authentication." 1>&2
fi
