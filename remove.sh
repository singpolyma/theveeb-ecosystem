#!/bin/sh

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if command -v emulate 1>&2; then
	emulate sh
fi

# Make sure HOME is set up
if [ -z "$HOME" ]; then
	HOME="`ls -d ~`"
fi

INTERACTIVE=0
while [ $# -gt 1 ]; do
	case "$1" in
		-d*)
			TVEDB="`echo "$1" | cut -c3-`"
			if [ -z "$TVEDB" ]; then
				TVEDB=">>"
			fi
			shift
		;;
		-*)
			echo "Unsupported switch $1" 1>&2
			exit 1
		;;
		*)
			if [ "$TVEDB" = ">>" ]; then
				TVEDB="$1"
				shift
			fi
		;;
	esac
done

# Check that a package was specified to remove
if [ -z "$1" ]; then
	echo "No package was specified." 1>&2
	exit 1
fi

# Auto-select install prefix
if [ -z "$PREFIX" ]; then
	PREFIX="$TVEROOT/"
fi

# Select directory for install logs
LOGDIR=""
if [ -d "$TVEROOT/Library/Caches" ]; then
	LOGDIR="$TVEROOT/Library/Caches/tve-remove"
else
	LOGDIR="$TVEROOT/var/cache/tve-remove"
fi
if ! mkdir -p "$LOGDIR"; then
	LOGDIR="$HOME/.tve-remove"
	if ! mkdir -p "$LOGDIR"; then
		echo "Could not access the install log directory." 1>&2
		exit 1
	fi
fi

# Determine which command to use for installing internal packages
INTERNAL="`command -v dpkg`"
if [ $? != 0 -o "`whoami`" != "root" ]; then
	INTERNAL="undeb"
else
	INTERNAL="dpkg --root="$TVEROOT/" -r"
fi

if [ -r "$LOGDIR/$1.prerm" ]; then
	sh "$LOGDIR/$1.prerm"
fi

if [ "$INTERNAL" != "undeb" ]; then
	if ! $INTERNAL "$1"; then
		echo "Removal failed." 1>&2
		exit 1
	fi
fi

if [ -r "$LOGDIR/$1" ]; then
	if ! xargs rm -fv < "$LOGDIR/$1"; then
		echo "Removal failed." 1>&2
		exit 1
	fi
	if ! rm -fv "$LOGDIR/$1"; then
		echo "Removal failed." 1>&2
		exit 1
	fi
elif [ "$INTERNAL" = "undeb" ]; then
	echo "$1 not installed." 1>&2
	exit 1
fi

if [ -r "$LOGDIR/$1.postrm" ]; then
	sh "$LOGDIR/$1.postrm"
fi

echo "$1 sucessfully removed."
