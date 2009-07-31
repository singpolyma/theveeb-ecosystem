#!/bin/sh

cd "`dirname "$0"`"
rm -rf ./data
mkdir -p ./data/home
if ! TOKENS="`TVEROOT="./data" OPEN="./scripts/authorize.sh" HOME="./data/home" ../login-start.sh`"; then
	echo "Error getting request tokens." 1>&2
	exit 1
fi
if [ -z "$TOKENS" ]; then
	echo "Error getting request tokens." 1>&2
	exit 1
fi
echo Got request tokens...
echo Authorized to test account...

if ! TVEROOT="./data" HOME="./data/home" ../login-finish.sh $TOKENS; then
	echo "Error getting access tokens." 1>&2
	exit 1
fi

if ! TVEROOT="./data" HOME="./data/home" ../login-check.sh $TOKENS; then
	echo "Login check failed." 1>&2
	exit 1
fi
