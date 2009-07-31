#!/bin/sh

TVEROOT="`dirname "$0"`"
cd "$TVEROOT"
mkdir -p "$TVEROOT/data/etc"
cp ../testrepo.txt data/etc/tve.list
TVEROOT="$TVEROOT/data"
if [ -z "$GNUPGHOME" ]; then
	GNUPGHOME="$HOME/.gnupg"
fi
if ! TVEROOT="$TVEROOT" TVEDB="$TVEROOT/tve.db" GNUPGHOME="$GNUPGHOME" HOME="$TVEROOT/home" ../run-update.sh; then
	echo "Update failed." 1>&2
	exit 1
fi
if ! T="`TVEROOT="$TVEROOT" TVEDB="$TVEROOT/tve.db" HOME="$TVEROOT/home" ../search/search`"; then
	echo "Database not updated properly." 1>&2
	exit 1
fi

echo "Updates successfully run."
