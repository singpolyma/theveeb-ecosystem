#!/bin/sh

if [ "." = "$1." ]; then
	echo "Please specify a package shortname." 1>&2
	exit 1
fi

if [ ! -d ./debian ]; then
	echo "No ./debian directory found." 1>&2
	exit 1
fi

echo "Setting up ./debian/$1 ..."

mkdir -p "./debian/$1/DEBIAN"
mkdir -p "./debian/$1/usr/bin"
mkdir -p "./debian/$1/usr/lib"
mkdir -p "./debian/$1/usr/share/man"
mkdir -p "./debian/$1/usr/share/info"
mkdir -p "./debian/$1/usr/share/doc/$1"

if [ -f ./configure ]; then
	echo "Running configure..."
	if ! command -v gcc; then
		echo "No gcc found in PATH." 1>&2
		exit 1
	fi
	sh ./configure --packaging --host="`gcc -dumpmachine`" --build="`gcc -dumpmachine`" --prefix=/usr --mandir=\$${prefix}/share/man --infodir=\$${prefix}/share/info CFLAGS="$CFLAGS" LDFLAGS="-Wl,-z,defs"
fi

if [ -f ./Makefile ]; then
	echo "Running make..."
	if command -v make; then
		make prefix="`pwd`/debian/$1/usr" install
	fi
fi

echo "Copying docs..."

cp -p ./debian/changelog "./debian/$1/usr/share/doc/$1/changelog.Debian"
gzip "./debian/$1/usr/share/doc/$1/changelog.Debian"
cp -p ./debian/copyright "./debian/$1/usr/share/doc/$1/copyright"
for i in `cat ./debian/docs`; do
	cp -pv "$i" "./debian/$1/usr/share/doc/$1"
done

echo "Generating debian data..."

echo "WARNING: please edit ./debian/$1/DEBIAN/control to have the Package: line at the top, and to resolve any shlibs/etc dependencies manually, before running xdebuild-pkg"
sed -e'/^Source:/d' ./debian/control | sed -e'/^$/d' | sed -e'/^Build-Depends:/d' | sed -e'/^Standards-Version/d' > "./debian/$1/DEBIAN/control"
cp -p ./debian/preinst "./debian/$1/DEBIAN/preinst"
cp -p ./debian/postinst "./debian/$1/DEBIAN/postinst"
cp -p ./debian/prerm "./debian/$1/DEBIAN/prerm"
cp -p ./debian/postrm "./debian/$1/DEBIAN/postrm"

cd "./debian/$1"
find . -type f | grep -v DEBIAN | cut -b3- | xargs md5sum > "DEBIAN/md5sums"
cd -
