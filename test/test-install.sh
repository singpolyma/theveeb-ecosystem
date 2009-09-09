#!/bin/sh

cd "`dirname "$0"`"
mkdir -p "./data/user"

if [ -z "$GNUPGHOME" ]; then
	GNUPGHOME="$HOME/.gnupg"
fi

if ! TVEROOT="./data" TVEDB="./data/tve.db" GNUPGHOME="$GNUPGHOME" HOME="./data/home" ../install.sh test; then
	echo "Install failed." 1>&2
	exit 1
fi

if [ ! -f './data/test' ]; then
	echo "Install failed." 1>&2
	exit 1
fi

if [ "`TVEROOT="./data" TVEDB="./data/tve.db" GNUPGHOME="$GNUPGHOME" HOME="./data/home" ../status/status test`" -ne 1 ]; then
	echo "Status Updating Failed" 1>&2
	exit 1
fi

echo "Install Succeeded" 1>&2
