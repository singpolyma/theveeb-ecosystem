# Find the file where OAuth tokens are and get them
OAUTHTOKENS="$HOME/.tve-oauth-tokens"
if [ ! -r "$OAUTHTOKENS" ]; then
	OAUTHTOKENS="$TVEROOT/etc/tve-oauth-tokens"
fi

if rm -f "$OAUTHTOKENS"; then
	echo "Logout successful."
else
	echo "Logout failed."
	exit 1
fi
