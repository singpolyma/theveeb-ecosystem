#!/bin/sh

# Some stuff from setup.sh... we want undeb to remain independent

# Get value for HOME on Windows
if [ -n "$USERPROFILE" ]; then
	HOME="$USERPROFILE"
elif [ -n "$HOMEPATH" ]; then
	HOME="$HOMEDRIVE$HOMEPATH"
fi

# How are we to tell if a command exists?
if ! N="`type this-does-not-exist 2>&1`" && N="`type type 2>&1`"; then
	cmdexists() {
		N="`type "$1" 2>&1`"
	}
else
	cmdexists() {
		N="`command -v "$1" 2>&1`" # -v switch not guarenteed to exist
	}
fi

# If we're under cygwin, fix paths
# TODO: check a cygwin-only env?
if cmdexists cygpath; then
	HOME="`cygpath -mas "$HOME"`"
	TEMP="`cygpath -mas "$TEMP"`"
	pwd() {
		PWD="`sh -c pwd`"
		cygpath -mas "$PWD"
	}
	abspth() {
		cygpath -mas "$1"
	}
else
	abspth() {
		# Get the absolute path for $1
		oldwd="`pwd`"
		cd "`dirname "$1"`"
		PTH="`pwd`"
		PTH="${PTH%/}"
		cd "$oldwd"
		echo "$PTH/`basename "$1"`"
	}
fi

decompress() {
	if [ -f "$1.tar" ]; then
		echo "Not compressed, no decompression necessary."
	elif [ -f "$1.tar.gz" ]; then
		if ! cmdexists gzip; then
			echo "You must have a version of gzip to unpack $1" 1>&2
			exit 1
		fi
		gzip -d "$1.tar.gz"
	elif [ -f "$1.tar.bz2" ]; then
		if ! cmdexists bzip2; then
			echo "You must have a version of bzip2 to unpack $1" 1>&2
			exit 1
		fi
		bzip2 -d "$1.tar.bz2"
	elif [ -f "$1.tar.bzip2" ]; then
		if ! cmdexists bzip2; then
			echo "You must have a version of bzip2 to unpack $1" 1>&2
			exit 1
		fi
		bzip2 -d "$1.tar.bzip2"
	elif [ -f "$1.tar.lzma" ]; then
		if ! cmdexists lzma; then
			echo "You must have a version of bzip2 to unpack $1" 1>&2
			exit 1
		fi
		lzma -d "$1.tar.lzma"
	else
		echo "ERROR: No control.tar.* found." 1>&2
		exit 1
	fi
}

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if cmdexists emulate; then
	emulate sh
fi

# Ensure we have neccesary utils (ar, tar)

if ! cmdexists ar; then
	echo "You must have a POSIXly-compliant version of ar to use $0" 1>&2
	exit 1
fi

if ! cmdexists tar; then
	echo "You must have a POSIXly-compliant version of tar to use $0" 1>&2
	exit 1
fi

# Verify that the user has invoked the script correctly

if [ -z "$1" ]; then
	echo "You must specify a package to install." 1>&2
	exit 1
fi

# Get the name of a safe temporary directory

if [ -n "$TMPDIR" ]; then
	temp=$TMPDIR
elif [ -n "$TEMP" ]; then
	temp="$TEMP"
elif [ -n "$TMP" ]; then
	temp="$TMP"
elif [ -d "/tmp" ]; then
	temp="/tmp"
else
	#fallback
	temp="."
fi

# Get a random directory name and try to create it
if cmdexists mktemp; then # Try to use mktemp
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
ar xv "$deb"
cd - # Pop back to where we were, just in case we forget where we are later

# Check that the package unpacked and is a package we can understand
DEB_VERSION=`cat "$temp/debian-binary"`
if [ -z "$DEB_VERSION" ]; then
	echo "ERROR: The package does not appear to be valid." 1>&2
	exit 1
elif [ "$DEB_VERSION" != "2.0" ]; then
	echo "WARN: debian-binary says $DEB_VERSION, expected 2.0 " 1>&2
fi

# NOTE: We do not check dependencies. Use a wrapper script.

# Find and verify PGP signature (currently only supports using GPG for this)
if [ -r "$temp/_gpgorigin" ]; then
	if cmdexists gpg; then
		if gpg --verify "$temp/_gpgorigin" "$temp/debian-binary" "$temp/control.tar"* "$temp/data.tar"*; then
			echo "PGP signature found and verified." 1>&2
		else
			echo "FATAL: PGP signature found and invalid." 1>&2
			exit 1
		fi
	else
		echo "WARN: PGP signature found, but GPG not installed." 1>&2
	fi
else
	echo "WARN: no PGP signature found for '$1'." 1>&2
fi

decompress "$temp/control"

cd "$temp"
tar xvf "$temp/control.tar"
cd -

if [ ! -r "$temp/md5sums" ]; then
	echo "FATAL: Could not verify package integrity." 1>&2
	exit 1
fi

decompress "$temp/data"

# Create a dir out
mkdir -p "$temp/out"

# Copy the data tar into it
cp "$temp/data.tar" "$temp/out"

if [ -f "$temp/preinst" ]; then
	sh "$temp/preinst" install
fi

# Unpack using tar
cd "$temp/out"
tar xvf data.tar
rm -f data.tar
cd - # Pop back to where we were, just in case we forget where we are later

# Verify integrity with md5sums
IFS="
"
for LINE in `cat "$temp/md5sums"`; do
	MD5="`echo "$LINE" | cut -d' ' -f1`"
	FILE="`echo "$LINE" | awk '{ print $2; }'`"
	if [ "$MD5" != "`md5 -q "$temp/out/$FILE"`" ]; then
		echo "Package integrity check failed." 1>&2
		exit 1
	fi
done
IFS=" "

echo "Package integrity check succeeded." 1>&2

# Copy the data to the dir where it will be installed
if [ -z "$PREFIX" ]; then
	PREFIX="/"
fi

# Get the absolute path for PREFIX
PREFIX="`abspth "$PREFIX"`"

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
for FILE in `find "$temp/out" | sed -e"s#^$temp/out[\\\\\\\\\/]\{0,1\}##"`; do
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
		if [ -n "$LOG" ]; then
			echo "$PREFIX/$FILE" >> "$LOG"
		fi
	fi
done
IFS=" "

if [ -f "$temp/postinst" ]; then
	sh "$temp/postinst" configure
fi

# Keep rm scripts around if we've been told what to do with them
if [ -n "$RMPATH" ]; then
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
