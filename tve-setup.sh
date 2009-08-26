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
		PWD="`command pwd`"
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

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if cmdexists emulate; then
	emulate sh
fi

# Find the network utility
if cmdexists wget 1>&2; then
	net2stdout() {
		if [ -n "$2" ]; then
			wget --header="$1" -q -O - "$2"
		else
			wget -q -O - "$1"
		fi
	}
	net2file() {
		if [ -n "$2" ]; then
			wget --header="$1" -q "$2"
		else
			wget -q "$1"
		fi
	}
elif cmdexists curl 1>&2; then
	net2stdout() {
		if [ -n "$2" ]; then
			curl -H"$1" -sfL "$2"
		else
			curl -sfL "$1"
		fi
	}
	net2file() {
		if [ -n "$2" ]; then
			curl -H"$1" -sfLO "$2"
		else
			curl -sfLO "$1"
		fi
	}
else
	net2stdout() {
		echo "You must have wget or curl installed." 1>&2
		exit 1
	}
	net2file() {
		echo "You must have wget or curl installed." 1>&2
		exit 1
	}
fi

# Find other TVE utils
findTVEscript() {
	localpath="`dirname "$0"`/$1.sh"
	if [ -x "$localpath" ]; then
		abspth "$localpath"
	else
		if [ -z "$2" ]; then
			echo "tve-$1"
		else
			echo "$2$1"
		fi
	fi
}

findTVEbinary() {
	localpath="`dirname "$0"`/$1/$1"
	if [ -x "$localpath" ]; then
		abspth "$localpath"
	else
		if [ -z "$2" ]; then
			echo "tve-$1"
		else
			echo "$2$1"
		fi
	fi
}
