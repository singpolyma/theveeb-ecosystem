#!/bin/sh

REQUEST="`oauthsign -c key123 -C sekret http://csclub.uwaterloo.ca:4567/oauth/request_token`"
TOKENS="`curl -s "$REQUEST"`"
# TODO: parse token/secret
#http://singpolyma.net/theveeb/authorize.php?oauth_token=TOKEN
