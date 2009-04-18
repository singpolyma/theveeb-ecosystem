#!/bin/sh

REQUEST="`oauthsign -c key123 -C sekret http://csclub.uwaterloo.ca:4567/oauth/request_token`"
TOKENS="`curl -s "$REQUEST"`"

TOKEN="`echo $TOKENS | sed 's/^oauth_token=\([^&]*\).*/\1/'`"
SECRET="`echo $TOKENS | sed 's/^[^&]*&oauth_token_secret=\(.*\)/\1/'`"

echo "$TOKEN $SECRET"
open "http://singpolyma.net/theveeb/authorize.php?oauth_token=$TOKEN" &
