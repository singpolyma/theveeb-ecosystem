#!/bin/sh

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if which emulate 1>&2; then
	emulate sh
fi

# Ensure we have neccesary utils (ar, tar)

AR=`which ar`
if [ -z "$AR" ]; then
	echo "You must have a POSIXly-compliant version of ar to use $0" 1>&2
	exit 1
fi

TAR=`which tar`
if [ -z "$TAR" ]; then
	echo "You must have a POSIXly-compliant version of tar to use $0" 1>&2
	exit 1
fi

# Verify that the user has invoked the script correctly

if [ -z "$1" ]; then
	echo "You must specify a package to install." 1>&2
	exit 1
fi

# Get the name of a safe temporary directory

if [ ! -z "$TMPDIR" ]; then
	temp=$TMPDIR
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

# Get a random directory name and try to create it
if which mktemp 1>&2; then # Try to use mktemp
	temp="`mktemp -d "$temp/undeb-$$-XXXXXX"`"
else
	temp="$temp/undeb-$$-$RANDOM-$RANDOM" #$RANDOM is non-standard and likely blank on your shell
	mkdir -p "$temp"
	if [ $? != 0 ]; then
		echo "ERROR: $temp is not writable (it may already exist)." 1>&2
		exit 1
	fi
fi

# Get the name of where we want the package file to live
deb="$temp/`basename $1`"

# Copy the package to its new home
cp "$1" "$deb"
if [ $? != 0 ]; then
	echo "ERROR: $deb could not be created." 1>&2
	exit 1
fi

# Unpack the package with ar
cd "$temp"
"$AR" xv "$deb"
cd - # Pop back to where we were, just in case we forget where we are later

# Check that the package unpacked and is a package we can understand
DEB_VERSION=`cat "$temp/debian-binary"`
if [ -z "$DEB_VERSION" ]; then
	echo "ERROR: The package does not appear to be valid." 1>&2
	exit 1
elif [ "$DEB_VERSION" != "2.0" ]; then
	echo "WARN: debian-binary says $DEB_VERSION, expected 2.0 " 1>&2
fi

# XXX: Should check dependencies? Should check md5sums. Should check _gpgorigin.

if [ -f "$temp/control.tar" ]; then
	echo "Not compressed, no decompression necessary."
elif [ -f "$temp/control.tar.gz" ]; then
	GZIP="`which gzip`"
	if [ -z "$GZIP" ]; then
		echo "You must have a version of gzip to unpack $1" 1>&2
		exit 1
	fi
	"$GZIP" -d "$temp/control.tar.gz"
elif [ -f "$temp/control.tar.bz2" ]; then
	BZIP2="`which bzip2`"
	if [ -z "$BZIP2" ]; then
		echo "You must have a version of bzip2 to unpack $1" 1>&2
		exit 1
	fi
	"$BZIP2" -d "$temp/control.tar.bz2"
elif [ -f "$temp/control.tar.bzip2" ]; then
	BZIP2="`which bzip2`"
	if [ -z "$BZIP2" ]; then
		echo "You must have a version of bzip2 to unpack $1" 1>&2
		exit 1
	fi
	"$BZIP2" -d "$temp/control.tar.bzip2"
else
	echo "ERROR: No control.tar.* found." 1>&2
	exit 1
fi

cd "$temp"
tar xvf "$temp/control.tar"
cd -

if [ -f "$temp/preinst" ]; then
	sh "$temp/preinst"
fi

# Determine what kind of data ball is being used and decompress it
if [ -f "$temp/data.tar" ]; then
	echo "Not compressed, no decompression necessary."
elif [ -f "$temp/data.tar.gz" ]; then
	GZIP="`which gzip`"
	if [ -z "$GZIP" ]; then
		echo "You must have a version of gzip to unpack $1" 1>&2
		exit 1
	fi
	"$GZIP" -d "$temp/data.tar.gz"
elif [ -f "$temp/data.tar.bz2" ]; then
	BZIP2="`which bzip2`"
	if [ -z "$BZIP2" ]; then
		echo "You must have a version of bzip2 to unpack $1" 1>&2
		exit 1
	fi
	"$BZIP2" -d "$temp/data.tar.bz2"
elif [ -f "$temp/data.tar.bzip2" ]; then
	BZIP2="`which bzip2`"
	if [ -z "$BZIP2" ]; then
		echo "You must have a version of bzip2 to unpack $1" 1>&2
		exit 1
	fi
	"$BZIP2" -d "$temp/data.tar.bzip2"
else
	echo "ERROR: No data.tar.* found." 1>&2
	exit 1
fi

# Create a dir out
mkdir -p "$temp/out"

# Copy the data tar into it
cp "$temp/data.tar" "$temp/out"

# Unpack using tar
cd "$temp/out"
tar xvf data.tar
rm -f data.tar
cd - # Pop back to where we were, just in case we forget where we are later

# Copy the data to the dir where it will be installed
if [ -z "$PREFIX" ]; then
	PREFIX="/"
fi
# Get the absolute path for PREFIX
cd "$PREFIX"
PREFIX="`pwd`"
PREFIX="${PREFIX%/}"
cd -

if ! mkdir -p "$PREFIX"; then
	echo "ERROR: files not installed (you may not have sufficient permissions)." 1>&2
	# Clean up our temporary directory
	rm -rf "$temp"
	exit 1
fi

if [ ! -w "$PREFIX" ]; then
	echo "ERROR: files not installed (you may not have sufficient permissions)." 1>&2
	# Clean up our temporary directory
	rm -rf "$temp"
	exit 1
fi

MUST_REBOOT=0
IFS="
"
for FILE in `find "$temp/out/" | sed -e"s#^$temp/out/##"`; do
	if [ -d "$temp/out/$FILE" ]; then
		if ! mkdir -p "$PREFIX/$FILE"; then
			echo "ERROR: files not installed (you may not have sufficient permissions)." 1>&2
			# Clean up our temporary directory
			rm -rf "$temp"
			exit 1
		fi
	else
		if ! mv -f "$temp/out/$FILE" "$PREFIX/$FILE"; then
			if [ $? -eq 110 ]; then
				MUST_REBOOT=1
			else
				echo "ERROR: files not installed (you may not have sufficient permissions)." 1>&2
				# Clean up our temporary directory
				rm -rf "$temp"
				exit 1
			fi
		fi
		# Only adds files to the remove log... so that we don't remove shared folders.
		# May result in empty dirs left behind.
		if [ ! -z "$LOG" ]; then
			echo "$PREFIX/$FILE" >> "$LOG"
		fi
	fi
done
IFS=" "

if [ -f "$temp/postinst" ]; then
	sh "$temp/postinst"
fi

# Keep rm scripts around if we've been told what to do with them
if [ ! -z "$RMPATH" ]; then
	mv -f "$temp/prerm" "$RMPATH".prerm
	mv -f "$temp/postrm" "$RMPATH".prerm
fi

# Clean up our temporary directory
rm -rf "$temp"

echo "Package '$1' installed to '$PREFIX' successfully."
if [ $MUST_REBOOT -eq 1 ]; then
	echo "You must reboot before installation will be complete."
	exit 110
fi
