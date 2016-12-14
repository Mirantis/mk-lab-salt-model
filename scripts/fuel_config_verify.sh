#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Import common functions
COMMONS=./common_functions.sh
if [ ! -f $COMMONS ]; then
	echo "File $COMMONS does not exist"
	exit 1
fi
. $COMMONS

# Verify that Salt master is correctly bootstrapped
salt-key
reclass-salt --top

# Verify that Salt minions are responding and the same version as master
salt-call --version
salt '*' test.version

# Wait for all nodes in current deployment to be available
wait_for $(get_nodes_names | wc -l)
