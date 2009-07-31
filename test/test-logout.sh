#!/bin/sh

cd "`dirname "$0"`"
mkdir -p ./data/home

if ! TVEROOT="./data" HOME="./data/home" ../logout.sh; then
	echo "Error logging out." 1>&2
	exit 1
fi

if TVEROOT="./data" HOME="./data/home" ../login-check.sh $TOKENS; then
	echo "Logout failed." 1>&2
	exit 1
fi

rm -rf ./data
