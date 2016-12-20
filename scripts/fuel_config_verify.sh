#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

CWD="$(dirname "$(readlink -f "$0")")"

# Import common functions
COMMONS=$CWD/common_functions.sh
if [ ! -f "$COMMONS" ]; then
	echo "File $COMMONS does not exist"
	exit 1
fi
. "$COMMONS"

# Verify that Salt master is correctly bootstrapped
salt-key
reclass-salt --top

# Verify that Salt minions are responding and have the same version as the master
salt-call --version
salt '*' test.version
