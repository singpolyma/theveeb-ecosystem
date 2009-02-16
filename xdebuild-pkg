#!/bin/sh

if [ "." = "$1." ]; then
	echo "Please specify a package shortname." 1>&2
	exit 1
fi

if [ ! -d ./debian ]; then
	echo "No ./debian directory found." 1>&2
	exit 1
fi

cd "./debian/$1/DEBIAN"
tar cvf control.tar *
gzip control.tar
mv control.tar.gz ..
cd -

cd "./debian/$1"
mv DEBIAN ..
mv control.tar.gz ..
tar cvf data.tar *
gzip data.tar
mkdir -p ../t
mv * ../t

mv ../t/data.tar.gz .
mv ../control.tar.gz .
echo "2.0" > debian-binary

ar rcov "$1.deb" debian-binary control.tar.gz data.tar.gz

rm -f debian-binary
rm -f control.tar.gz
rm -f data.tar.gz

mv ../DEBIAN .
mv ../t/* .
rm -rf ../t
cd -

mv "./debian/$1/$1.deb" .
