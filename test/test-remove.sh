#!/bin/sh

cd "`dirname "$0"`"

if ! TVEROOT="./data" TVEDB="./data/tve.db" HOME="./data/home" ../remove.sh test; then
	echo "Removal Failed" 1>&2
	exit 1
fi

if [ -f './data/test' ]; then
	echo "Removal Failed" 1>&2
	exit 1
fi

if [ "`TVEROOT="./data" TVEDB="./data/tve.db" HOME="./data/home" ../status/status test`" -ne 0 ]; then
	echo "Status Updating Failed" 1>&2
	exit 1
fi


echo "Removal Succeeded" 1>&2
