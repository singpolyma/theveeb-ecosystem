#!/bin/sh

cd "`dirname "$0"`"
mkdir -p "./data/etc"
cp ../testrepo.txt data/etc/tve.list
if [ -z "$GNUPGHOME" ]; then
	GNUPGHOME="$HOME/.gnupg"
fi
if ! TVEROOT="./data" TVEDB="./data/tve.db" GNUPGHOME="$GNUPGHOME" HOME="./data/home" ../run-update.sh; then
	echo "Update failed." 1>&2
	exit 1
fi
if ! T="`TVEROOT="./data" TVEDB="./data/tve.db" HOME="./data/home" ../search/search`"; then
	echo "Database not updated properly." 1>&2
	exit 1
fi

echo "Updates successfully run."
