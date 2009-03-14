#!/bin/sh

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if which emulate 1>&2; then
	emulate sh
fi

# Handle switches
INTERACTIVE=0
while [ $# -gt 0 ]; do
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
			else # We have hit the first non-switch
				break
			fi
		;;
	esac
done

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

# Verify the presence of oauthsign
if ! which oauthsign 1>&2; then
	echo "You need the oauthsign utility from oauth-utils installed to use this script." 1>&2
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

# Find the file where OAuth tokens are and get them
OAUTHTOKENS="$HOME/.tve-oauth-tokens"
if [ "`whoami`" = "root" -o ! -r "$OAUTHTOKENS" ]; then
	OAUTHTOKENS="$TVEROOT/etc/tve-oauth-tokens"
fi
if [ ! -r "$OAUTHTOKENS" ]; then
	echo "You don't seem to have valid OAuth tokens in $TVEROOT/etc/tve-oauth-tokens or $HOME/.tve-oauth-tokens" 1>&2
	exit 1
fi
TOKEN="`cut -d' ' -f1 < "$OAUTHTOKENS"`"
SECRET="`cut -d' ' -f2 < "$OAUTHTOKENS"`"

# OAuth Consumer token and secret
# TODO get a better consumer keypair set up
CONSUMER_TOKEN="key123"
CONSUMER_SECRET="sekret"

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
# Try to use mktemp
if which mktemp 1>&2; then
	temp="`mktemp -d "$temp/tve-install-$$-XXXXXX"`"
else
	temp="$temp/tve-install-$$-$RANDOM-$RANDOM" #$RANDOM is non-standard and likely blank on your shell
	mkdir -p "$temp"
fi

# Determine if there is an external package manager to use
EXTERNAL="`which apt-get`"
if [ $? != 0 ]; then
	EXTERNAL=""
else
	EXTERNAL="apt-get install -y"
fi

# Determine which command to use for installing internal packages
INTERNAL="`which dpkg`"
if [ $? != 0 -o "`whoami`" != "root" ]; then
	INTERNAL="./undeb"
else
	INTERNAL="dpkg --root="$TVEROOT/" -i"
fi

# do_install KIND PACKAGE
do_install () {
	# If interactive, ask for confirmation
	if [ $INTERACTIVE != 0 ]; then
		read -p "Install $1 ${2}? [Yn] " YN
		if [ "$YN" = "N" -o "$YN" = "n" -o "$YN" = "No" -o "$YN" = "no" ]; then
			echo "You opted not to install $1 ${2}. Aborting install..."
			exit 2
		fi
	fi
	# Extract the download URL from the database
	DATA="`TVEDB="$TVEDB" search/search -v "$2"`"
	URL="`echo "$DATA" | grep Download | cut -d' ' -f2`"
	# Sign the URL with oauth utils (oauthsign)
	URL="`oauthsign -c $CONSUMER_TOKEN -C $CONSUMER_SECRET -t $TOKEN -T $SECRET "$URL"`"
	# Get remote URL and download deb file with GET
	if ! $GET "$URL" > "$temp/$2.deb"; then
		echo "Error downloading ${2}... Aborting..."
		exit 1
	fi
	# Verify size and MD5 from database
	SIZE="`echo "$DATA" | grep Size | cut -d' ' -f2`"
	REALSIZE="`wc -c "$temp/$2.deb" | awk '{ print $1 }'`"
	if [ "$SIZE" != "$REALSIZE" ]; then
		echo "Integrity check for $1 failed. Size does not match." 1>&2
		exit 1
	fi
	MD5="`echo "$DATA" | grep MD5sum | cut -d' ' -f2`"
	REALMD5="`md5/md5 -q "$temp/$2.deb"`"
	if [ "$MD5" != "$REALMD5" ]; then
		echo "Integrity check for $1 failed. MD5 sum does not match." 1>&2
		exit 1
	fi
	# Install deb file with $INTERNAL
	LOG="$LOGDIR/$2" PREFIX="$TVEROOT/" $INTERNAL "$temp/$2.deb"
	if [ $? != 0 ]; then
		echo "Error unpacking ${2}."
		exit 1
	fi
	# UPDATE status in DB for this 2 (write set-status C utility)
	if [ "$1" = "dependency" ]; then
		if [ "`status/status "$2"`" -ne 0 ]; then
			status/status "$2" .
		else
			status/status "$2" 2 # Set to 2 if installing for the first time as a dependency
		fi
	else
		status/status "$2" .
	fi
}

# Get dependencies
DEP="`TVEDB="$TVEDB" depends/depends "$1"`"
if [ $? != 0 ]; then
	# Error message was already output by the depends command
	exit 1
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
		do_install "dependency" "$package"
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

do_install "" "$1"

# remove temp dir
rm -rf "$temp"

echo "$1 sucessfully installed (with all dependencies)."
