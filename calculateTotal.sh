#!/bin/sh

# This function calculates the price to install given packages, including dependencies
# The output is a single integer and a newline
# Example:
# >calculateTotal.sh somePackage someOtherPackage
# 15

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

depends=`findTVEbinary depends`
search=`findTVEbinary search`
status=`findTVEbinary status`

if [ "$#" -lt 1 ]; then
	echo "Expected a package"
	exit 1
fi

# Initialize the price to 0
price=0
packages=''

# Get the dependency list for each given package
while [ "$#" -gt 0 ]; do
	# Get the dependencies that will also be installed
	depList=`"$depends" "$1"`

	# Remove the ones that aren't under our control, and pull out only the package names
	depList=`echo "$depList" | grep '^I ' | cut -f 2 -d ' '`

	# Append this package and its dependencies to the packages list 
	packages=`echo -e "$packages\n$1\n$depList"`

	# Now move to the next package
	shift
done

# Iterate over the package list
IFS='
'

# Take out any blank lines, and all duplicates
for package in `echo "$packages" | grep '^.' | sort | uniq`; do
	# Get the price data
	packageData=`"$search" -v "$package"` 
	# Check to make sure this is a package
	if [ -z "$packageData" ]; then
		echo "Unknown Package: $package" 1>&2
		continue;
	fi
	# Check if user owns this package
	if [ "`$status -o "$package"`" == 0 ]; then
		thisPrice=`echo "$packageData" | grep '^Price:' | cut -f 2 -d ' '`
		if [ -n "$thisPrice" ]; then
			price=`expr "$thisPrice" + "$price"`
		fi
	fi
done

echo "$price"
