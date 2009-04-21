#!/bin/sh

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

# Find the command to open a URL, if there is one
OPEN=""
if command -v xdg-open 1>&2; then
	OPEN="xdg-open"
elif command -v open 1>&2; then
	OPEN="open"
elif command -v cmd 1>&2; then
	# Why do we need zsh? win-bash won't call cmd correctly
	# Why not fix win-bash? I can't get it to compile
	# Why not use zsh for primary shell? It doesn't have -v on command builtin
	if command -v zsh 1>&2; then
		USE_ZSH=1
		OPEN="cmd /c start"
	fi
fi

REQUEST="`oauthsign -c key123 -C sekret http://csclub.uwaterloo.ca:4567/oauth/request_token`"
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

# This is the url to send the user to
URL="http://singpolyma.net/theveeb/authorize.php?oauth_token=$TOKEN" 

# Output the tokens
echo "$TOKEN $SECRET"

if [ -n "$OPEN" ]; then
	# If we can open urls for the user, do so
	if [ $USE_ZSH -eq 1 ]; then
		zsh -c "$OPEN '$URL'"
	else
		$OPEN "$URL" &
	fi
else
	# If we can't, output the url they should go to on their own
	echo "Go to \"$URL\" in a browser to continue authentication." 1>&2
fi
