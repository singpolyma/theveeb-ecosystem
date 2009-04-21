# Get value for HOME on Windows
if [ -n "$USERPROFILE" ]; then
	HOME="$USERPROFILE"
elif [ -n "$HOMEPATH" ]; then
	HOME="$HOMEDRIVE$HOMEPATH"
fi

# How are we to tell if a command exists?
if ! N="`type this-does-not-exist 2>&1`" -a N="`type type 2>&1`"; then
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
fi

# Tell zsh we expect to be treated like an sh script
# zsh really should take the hint from the shebang line
if cmdexists emulate; then
	emulate sh
fi

# Find the network utility
if cmdexists wget 1>&2; then
	net2stdout() {
		wget -q -O - "$1"
	}
elif cmdexists curl 1>&2; then
	net2stdout() {
		curl -sfL "$1"
	}
else
	net2stdout() {
		echo "You must have wget or curl installed." 1>&2
		exit 1
	}
fi

