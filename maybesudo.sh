#!/bin/sh

if [ -r "`dirname "$0"`"/tve-setup.sh ]; then
	. "`dirname "$0"`"/tve-setup.sh
else
	. "$TVEROOT"/usr/lib/tve-setup.sh
fi

if [ -w "$TVEROOT/" ]; then
	eval $*
else
	if cmdexists gksudo; then
		gksudo -k $*
	elif cmdexists gksu; then
		gksu -k $*
	elif cmdexists kdesudo; then
		kdesudo $*
	elif cmdexists kdesu; then
		kdesu $*
	elif cmdexists MacSudo; then
		MacSudo -p"The Veeb Ecosystem" $*
	elif cmdexists xterm; then
		if cmdexists sudo; then
			xterm -e sudo $*
		else
			echo "Cannot find a sudo command." 1>&2
			exit 1
		fi
	else
		echo "Cannot find a sudo command." 1>&2
		exit 1
	fi
fi
