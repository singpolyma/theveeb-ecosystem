#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
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
		-t*)
			OAUTHTOKENFILE="`echo "$1" | cut -c3-`"
			if [ -z "$OAUTHTOKENFILE" ]; then
				OAUTHTOKENFILE=">>"
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
			elif [ "$OAUTHTOKENFILE" = ">>" ]; then
				OAUTHTOKENFILE="$1"
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

# Verify the presence of oauthsign
if ! cmdexists oauthsign; then
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
if cmdexists mktemp; then
	temp="`mktemp -d "$temp/tve-install-$$-XXXXXX"`"
else
	temp="$temp/tve-install-$$-$RANDOM-$RANDOM" #$RANDOM is non-standard and likely blank on your shell
	mkdir -p "$temp"
fi

# Determine if there is an external package manager to use
if ! cmdexists apt-get; then
	EXTERNAL=""
else
	EXTERNAL="apt-get install -y"
fi

# Determine which command to use for installing internal packages
INTERNAL="`cmdexists dpkg`"
if [ $? != 0 -o "`whoami`" != "root" ]; then
	INTERNAL="sh `findTVEscript undeb " "`"
else
	INTERNAL="dpkg --root="$TVEROOT/" -i"
fi

DEPENDS="`findTVEbinary depends`"
SEARCH="`findTVEbinary search`"
MD5UTIL="`findTVEbinary md5 " "`"
STATUS="`findTVEbinary status`"

MUST_REBOOT=0

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
	DATA="`TVEDB="$TVEDB" "$SEARCH" -nve "$2"`"
	URL="`echo "$DATA" | grep Download | cut -d' ' -f2`"
	if [ -z "$URL" ]; then
		echo "Package $2 not found." 1>&2
		exit 1
	fi
	# Get token for this BASEURL
	BASEURL="`echo "$DATA" | grep BaseURL | cut -d' ' -f2`"
	TOKENS="`getTVETokens "$BASEURL" "$OAUTHTOKENFILE"`"
	# Sign the URL with oauth utils (oauthsign)
	if [ -n "$TOKENS" ]; then
		URL="`getTVEAuthRequest "$TOKENS" "$URL"`"
	fi
	# Get remote URL and download deb file with net2stdout
	if ! net2stdout "$URL" > "$temp/$2.deb"; then
		echo "Error downloading ${2}... Aborting..."
		exit 1
	fi
	# Verify size and MD5 from database
	SIZE="`echo "$DATA" | grep Size | cut -d' ' -f2`"
	REALSIZE="`wc -c "$temp/$2.deb" | awk '{ print $1 }'`"
	if [ "$SIZE" != "$REALSIZE" ]; then
		echo "Integrity check for $2 failed. Size does not match." 1>&2
		exit 1
	fi
	MD5="`echo "$DATA" | grep MD5sum | cut -d' ' -f2`"
	REALMD5="`"$MD5UTIL" -q "$temp/$2.deb"`"
	if [ "$MD5" != "$REALMD5" ]; then
		echo "Integrity check for $2 failed. MD5 sum does not match." 1>&2
		exit 1
	fi
	# Install deb file with $INTERNAL
	if ! LOG="$LOGDIR/$2" RMPATH="$LOGDIR/$2" PREFIX="$TVEROOT/" eval $INTERNAL "$temp/$2.deb"; then
		if [ $? -eq 110 ]; then
			MUST_REBOOT=1
		else
			echo "Error unpacking ${2}."
			exit 1
		fi
	fi
	# UPDATE status in DB
	if [ "$1" = "dependency" ]; then
		if [ "`"$STATUS" "$2"`" -ne 0 ]; then
			"$STATUS" "$2" .
		else
			"$STATUS" "$2" 2 # Set to 2 if installing for the first time as a dependency
		fi
	else
		"$STATUS" "$2" .
		# Add Uninstall entry on Windows
		if cmdexists reg; then
			reg ADD "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$2" /v "DisplayName" /d "$2" /f
			reg ADD "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$2" /v "UninstallString" /d "\$\\\"$TVEROOT\\bin\\sh.exe\$\\\" -c tve-remove $2" /f
			reg ADD "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$2" /v "NoModify" /t REG_DWORD /d 1 /f
			reg ADD "HKLM\\Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\$2" /v "NoRepair" /t REG_DWORD /d 1 /f
		fi
	fi
}

# do_manual PACKAGE
do_manual() {

	# Get dependencies
	DEP="`TVEDB="$TVEDB" "$DEPENDS" "$1"`"
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
#		$EXTERNAL $EXT2INSTALL
		if [ $? != 0 ]; then
			echo "External dependency install failure." 1>&2
			exit 1
		fi
	fi

	do_install "" "$1"

	echo "$1 sucessfully installed (with all dependencies)."

}

while [ $# -gt 0 ]; do
	do_manual "$1"
	shift
done

# remove temp dir
rm -rf "$temp"

if [ $MUST_REBOOT -eq 1 ]; then
	exit 110
fi
