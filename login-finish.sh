#!/bin/sh

REQUEST="`oauthsign -c key123 -C sekret -t $1 -T $2 http://csclub.uwaterloo.ca:4567/oauth/access_token`"
TOKENS="`curl -s "$REQUEST"`"

TOKEN="`echo $TOKENS | sed 's/^oauth_token=\([^&]*\).*/\1/'`"
SECRET="`echo $TOKENS | sed 's/^[^&]*&oauth_token_secret=\(.*\)/\1/'`"

echo "$TOKEN $SECRET" > "$HOME/.tve-oauth-tokens"
