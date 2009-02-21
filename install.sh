#!/bin/sh

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if which emulate 1>&2; then
	emulate sh
fi

INTERACTIVE=0
while [ $# -gt 1 ]; do
	case "$1" in
		-i)
			INTERACTIVE=1
			shift
		;;
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

# Make sure HOME is set up
if [ -z "$HOME" ]; then
	HOME="`ls -d ~`"
fi

# Check that a package was specified to install
if [ -z "$1" ]; then
	echo "No package was specified." 1>&2
	exit 1
fi

# Find the network utility
if which wget 1>&2; then
	GET="wget -q -O -"
elif which curl 1>&2; then
	GET="curl -sfL"
else
	echo "You must have wget or curl installed." 1>&2
	exit 1
fi

if ! which oauthsign 1>&2; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
	exit 1
fi

# Get dependencies
DEP="`TVEDB="$TVEDB" depends/depends "$1"`"
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

# Determine if there is an external package manager to use
EXTERNAL="`which apt-get`"
if [ $? != 0 ]; then
	EXTERNAL=""
else
	EXTERNAL="sudo apt-get install -y"
fi

# Determine which command to use for installing internal packages
INTERNAL="`which dpkg`"
if [ $? != 0 -o "`whoami`" != "root" ]; then
	INTERNAL="./undeb"
else
	INTERNAL="dpkg --root="$TVEROOT/" -i"
fi

# Install dependencies
EXT2INSTALL=""

# Set IFS so that for splits on newlines and not spaces
OIFS="$IFS"
IFS="
"
for LINE in $DEP; do
	IFS="$OIFS"
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
		# Extract the download URL from the database
		URL="`TVEDB="$TVEDB" search/search -v "$package" | grep Download | cut -d' ' -f2`"
		# TODO get keys from file... don't hard-code them
		# Sign the URL with oauth utils (oauthsign)
		URL="`oauthsign -c key123 -C sekret -t K7bSir10JPYlrWqGjhZsvQ -T 2H1QJAAz47KSfntAm1rUNWqHOYwtorKfQX7JsfuGDQ "$URL"`"
		# Get remote URL and download deb file with GET
		if ! $GET "$URL" > "$temp/$package.deb"; then
			echo "Error downloading $package... Aborting..."
			exit 1
		fi
		# Install deb file with $INTERNAL
		LOG="$LOGDIR/$package" PREFIX="$TVEROOT/" $INTERNAL "$temp/$package.deb"
		# TODO: UPDATE status in DB for this package (write set-status C utility)
	fi
done

# Actually install external dependencies, if there are any
if [ ! -z "$EXT2INSTALL" ]; then
	# If interactive, ask for confirmation
	if [ $INTERACTIVE != 0 ]; then
		read -p "Install external dependencies ${EXT2INSTALL}? [Yn] " YN
		if [ "$YN" = "N" -o "$YN" = "n" -o "$YN" = "No" -o "$YN" = "no" ]; then
			echo "You opted not to install required dependencies ${EXT2INSTALL}. Aborting install..."
			exit 2
		fi
	fi
	$EXTERNAL $EXT2INSTALL
	if [ $? != 0 ]; then
		echo "External dependency install failure." 1>&2
		exit 1
	fi
fi

# If interactive, ask for confirmation
if [ $INTERACTIVE != 0 ]; then
	read -p "Install ${1}? [Yn] " YN
	if [ "$YN" = "N" -o "$YN" = "n" -o "$YN" = "No" -o "$YN" = "no" ]; then
		echo "You opted not to install ${1}. Aborting install..."
		exit 2
	fi
fi
# If all dependencies succeeded, install package
# TODO