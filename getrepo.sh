#!/bin/sh

oldwd="`pwd`"

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
	if [ -f "~/.tve.list" ]; then
		LISTFILE="~/.tve.list"
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
				if wget -q "${baseurl}dists/${distro}/Release"; then
					if wget -q "${baseurl}dists/${distro}/Release.gpg"; then
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
					if wget -q "${baseurl}dists/${distro}/${section}/binary-${ARCH}/Packages.gz"; then
						#Verify size and MD5 from Release file
						size="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f3`"
						realsize="`ls -l Packages.gz | sed -e 's/[^ ]* [^ ] [^ ]* [^ ]* \([^ ]*\).*/\1/g'`"
						if [ "$size" != "$realsize" ]; then
							echo "ERROR: size of Packages.gz does not match" 1>&2
							exit 1
						fi
						md5="`grep "${section}/binary-${ARCH}/Packages.gz" Release | cut -d' ' -f2`"
						realmd5="`"$oldwd/md5/md5" < Packages.gz`"
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
rm -rf "$temp"
cd "$oldwd"
