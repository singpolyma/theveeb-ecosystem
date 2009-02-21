#!/bin/sh

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if which emulate 1>&2; then
	emulate sh
fi

oldwd="`pwd`"

# Make sure HOME is set up
if [ -z "$HOME" ]; then
	HOME="`ls -d ~`"
fi

if [ ! -z "$1" -a "`echo "$1" | cut -c-2`" = "-c" ]; then
	LISTFILE="`echo "$1" | cut -c3-`"
fi
if [ -z "$LISTFILE" -a ! -z "$1" -a "$1" = "-c" ]; then
	LISTFILE="$2"
fi
if [ -z "$LISTFILE" -a ! -z "$TVELIST" ]; then
	LISTFILE="$TVELIST"
fi
if [ -z "$LISTFILE" ]; then
	if [ -f "$HOME/.tve.list" ]; then
		LISTFILE="$HOME/.tve.list"
	elif [ -f "$TVEROOT/etc/tve.list" ]; then
		LISTFILE="/etc/tve.list"
	elif [ -f "/Program\ Files/TheVeeb/etc/tve.list" ]; then
		LISTFILE="/Program\ Files/TheVeeb/etc/tve.list"
	else
		echo "No tve.list file found." 1>&2
		exit 1
	fi
fi

# Don't mess up the current directory
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
temp="$temp/getrepo-$$-$RANDOM-$RANDOM"
mkdir -p "$temp"

#Get system architechture
if [ -z "$ARCH" ]; then
	ARCH="`uname -m | sed -e 's/i.86/i386/'`"
fi
if [ -z "$ARCH" ]; then
	echo "Could not detect the system architecture. Please set ARCH manually." 1>&2
	exit 1
fi
if [ "$ARCH" = "x86" ]; then
	ARCH="i386"
fi

# Find the network utility
if which wget 1>&2; then
	GET="wget -q"
elif which curl 1>&2; then
	GET="curl -sfLO"
else
	echo "You must have wget or curl installed." 1>&2
	exit 1
fi

#Loop line-by-line through a setings file
while read LINE ; do
	cd "$temp" # In the loop so that resative paths will work for LISTFILE
	#Strip whitespace from line
	LINE="`echo "$LINE" | sed -e 's/^ *//g;s/ *$//g'`"
	#Ignore blank lines
	if [ ! -z "$LINE" ]; then
		#Ignore lines staring with #
		case "$LINE" in
			\#*)
				;;
			*)
				#Tokenize line into baseurl, distro, and sections (by whitespace)
				baseurl="`echo "$LINE" | cut -s -d' ' -f2`"
				distro="`echo "$LINE" | cut -s -d' ' -f3`"
				#Output '#' + baseurl to STDOUT
				echo "#$baseurl"
				#Get (baseurl + 'dists/' + distro + '/Release') and (baseurl + 'dists/' + distro + '/Release.gpg')
				if $GET "${baseurl}dists/${distro}/Release"; then
					if $GET "${baseurl}dists/${distro}/Release.gpg"; then
						#Verify that the signature is valid
						if ! gpg --verify Release.gpg Release; then
							echo "ERROR: Could not verify Release signature" 1>&2
							exit 1
						fi
					else
						echo "ERROR: Could not verify Release signature" 1>&2
						exit 1
					fi
				else
					echo "ERROR: Could not verify Release signature" 1>&2
					exit 1
				fi

				#For each setion get (baseurl + 'dists/' + distro + '/' + section + '/binary-' + architecture + '/Packages.gz')
				for section in $LINE; do
					if [ -z "$section" -o "deb" = "$section" -o "$baseurl" = "$section" -o "$distro" = "$section" ]; then
						continue
					fi
					if $GET "${baseurl}dists/${distro}/${section}/binary-${ARCH}/Packages.gz"; then
						#Verify size and MD5 from Release file
						size="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f3`"
						realsize="`wc -c Packages.gz | awk '{ print $1 }'`"
						if [ "$size" != "$realsize" ]; then
							echo "ERROR: size of Packages.gz does not match" 1>&2
							exit 1
						fi
						md5="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f2`"
						realmd5="`"$oldwd/md5/md5" -b Packages.gz`"
						if [ "$md5" != "$realmd5" ]; then
							echo "ERROR: md5 of Packages.gz does not match" 1>&2
							exit 1
						fi
						#Decompress Packages.gz and output contents to STDOUT
						gzip -q -c -d Packages.gz
					fi
					rm -f Packages.gz
				done
				;;
		esac
	fi
done < "$LISTFILE"

# Cleanup
rm -rf "$temp" 1>&2
cd "$oldwd"
