#!/bin/sh

# TODO: Support switches -d, -c, -i
INTERACTIVE=0

# Make sure HOME is set up
if [ -z "$HOME" ]; then
	HOME="`ls -d ~`"
fi

# Check that a package was specified to install
if [ -z "$1" ]; then
	echo "No package was specified." 1>&2
	exit 1
fi

# Get dependencies
DEP="`depends/depends "$1"`"
if [ $? != 0 ]; then
	# Error message was already output by the depends command
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

# Select a temporary directory
if [ ! -z "$TMPDIR" ]; then
	temp="$TMPDIR"
elif [ ! -z "$TEMP" ]; then
	temp="$TEMP"
elif [ ! -z "$TMP" ]; then
	temp="$TMP"
elif [ -d "/tmp" ]; then
	temp="/tmp"
else
	#fallback
	temp="."
fi
temp="$temp/tve-install-$$-$RANDOM-$RANDOM"
mkdir -p "$temp"

# Find the network utility
if which wget 1>&2; then
	GET="wget -q -O -"
elif which curl 1>&2; then
	GET="curl -sfL"
else
	echo "You must have wget or curl installed." 1>&2
	exit 1
fi

# Determine if there is an external package manager to use
EXTERNAL="`which apt-get`"
if [ $? != 0 ]; then
	EXTERNAL=""
else
	EXTERNAL="sudo apt-get install -y"
fi

# Determine which command to use for installing internal packages
INTERNAL="`which dpkg`"
if [ $? != 0 ]; then
	INTERNAL="undeb"
else
	INTERNAL="sudo dpkg -i"
fi

# Install dependencies
EXT2INSTALL=""

# Set IFS so that for splits on newlines and not spaces
IFS="
"
for LINE in $DEP; do
	package="`echo "$LINE" | cut -d' ' -f2`"
	if [ "`echo "$LINE" | cut -d' ' -f1`" = "E" ]; then
		if [ -z "$EXTERNAL" ]; then
			echo "No external package manager found to install ${package}." 1>&2
			exit 1
		fi
		EXT2INSTALL="$EXT2INSTALL $package"
	else
		# If interactive, ask for confirmation
		if [ $INTERACTIVE != 0 ]; then
			read -p "Install dependency ${package}? [Yn] " YN
			if [ "$YN" = "N" -o "$YN" = "n" -o "$YN" = "No" -o "$YN" = "no" ]; then
				echo "You opted not to install required dependency ${package}. Aborting install..."
				exit 2
			fi
		fi
		echo "internal $package"
		# TODO: Print remote path in depends/depends, download it here to temp file with wget or curl
		# TODO: Install deb file with $INTERNAL
		# TODO: UPDATE status in DB for this package (write set-status C utility)
		#LOG="$LOGDIR/$package" $INTERNAL "$path"
	fi
done

# Actually install external dependencies
# If interactive, ask for confirmation
if [ $INTERACTIVE != 0 ]; then
	read -p "Install external dependencies ${EXT2INSTALL}? [Yn] " YN
	if [ "$YN" = "N" -o "$YN" = "n" -o "$YN" = "No" -o "$YN" = "no" ]; then
		echo "You opted not to install required dependencies ${EXT2INSTALL}. Aborting install..."
		exit 2
	fi
fi
#$EXTERNAL $EXT2INSTALL
echo "would $EXTERNAL $EXT2INSTALL"
if [ $? != 0 ]; then
	echo "External dependency install failure." 1>&2
	exit 1
fi

# If all dependencies succeeded, install package
# TODO
