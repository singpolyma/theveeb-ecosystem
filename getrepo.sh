#!/bin/sh

oldwd="`pwd`"

# Don't mess up the current directory
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
temp="$temp/getrepo-$$-$RANDOM-$RANDOM"
mkdir -p "$temp"
cd "$temp"

#Get system architechture (i386)
ARCH="i386" # XXX: Maybe detect with gcc if present or just have in a config file/generated before packaging/distributing this script

#Loop line-by-line through a setings file
while read LINE ; do
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
done < "$oldwd/testrepo.txt" # Make this configurable on the command line

# Cleanup
rm -rf "$temp"
cd "$oldwd"
