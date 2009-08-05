#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
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
		LISTFILE="$TVEROOT/etc/tve.list"
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
# Try to use mktemp
if cmdexists mktemp; then
	temp="`mktemp -d "$temp/tve-getrepo-$$-XXXXXX"`"
else
	temp="$temp/tve-getrepo-$$-$RANDOM-$RANDOM" #$RANDOM is non-standard and likely blank on your shell
	mkdir -p "$temp"
fi

# Get system architechture, normalise, and possibly prepend kernel
if [ -z "$ARCH" ]; then
	ARCH="`uname -m | sed -e 's/i.86/i386/'`"
fi
if [ -z "$ARCH" ]; then
	echo "Could not detect the system architecture. Please set ARCH manually." 1>&2
	exit 1
fi
case $ARCH in
	x86)
		ARCH="i386"
	;;
	x86_64)
		ARCH="amd64"
	;;
esac
KERNEL="`uname -s | tr '[:upper:]' '[:lower:]'`"
if [ -n "$KERNEL" -a "$KERNEL" != "linux" ]; then
	ARCH="$KERNEL-$ARCH"
fi

PWD="`pwd`"
MD5="`findTVEbinary md5 "$PWD/"`"

#Loop line-by-line through a setings file
while read LINE ; do
	cd "$temp" # In the loop so that relative paths will work for LISTFILE
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
				if net2file "${baseurl}dists/${distro}/Release"; then
					if net2file "${baseurl}dists/${distro}/Release.gpg"; then
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
					if net2file "${baseurl}dists/${distro}/${section}/binary-${ARCH}/Packages.gz"; then
						#Verify size and MD5 from Release file
						size="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f3`"
						realsize="`wc -c Packages.gz | awk '{ print $1 }'`"
						if [ "$size" != "$realsize" ]; then
							echo "ERROR: size of Packages.gz does not match" 1>&2
							exit 1
						fi
						md5="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f2`"
						realmd5="`"$MD5" -q Packages.gz | tr -d "\n"`"
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
