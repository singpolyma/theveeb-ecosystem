#!/bin/sh

TVEROOT="`dirname "$0"`"
cd "$TVEROOT"
rm -rf data
mkdir -p data/home
TVEROOT="$TVEROOT/data"
if ! TOKENS="`TVEROOT="$TVEROOT" OPEN="$TVEROOT/../scripts/authorize.sh" HOME="$TVEROOT/home" ../login-start.sh`"; then
	echo "Error getting request tokens." 1>&2
	exit 1
fi
if [ -z "$TOKENS" ]; then
	echo "Error getting request tokens." 1>&2
	exit 1
fi
echo Got request tokens...
echo Authorized to test account...

if ! TVEROOT="$TVEROOT" HOME="$TVEROOT/home" ../login-finish.sh $TOKENS; then
	echo "Error getting access tokens." 1>&2
	exit 1
fi

if ! TVEROOT="$TVEROOT" HOME="$TVEROOT/home" ../login-check.sh $TOKENS; then
	echo "Login check failed." 1>&2
	exit 1
fi
