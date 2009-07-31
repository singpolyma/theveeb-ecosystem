#!/bin/sh

if ! T="`curl -s "$1&test_session" -d'authorize=1'`"; then
	echo "Error authorizing." 1>&2
	exit 1
fi
