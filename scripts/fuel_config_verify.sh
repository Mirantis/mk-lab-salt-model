#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Verify that Salt master is correctly bootstrapped
salt-key
reclass-salt --top

# Verify that Salt minions are responding and the same version as master
salt-call --version
salt '*' test.version

# Get list of hostnames in current deployment
hosts=(`salt-call pillar.get linux:network:host | egrep '0.*:' | sed -e 's/  *//' -e 's/://'`)
wanted=${#hosts[@]}

# Default max waiting time is 5mn
MAX_WAIT=${MAX_WAIT:-300}
while [ true ]; do
	nb_nodes=`salt '*' test.ping | egrep ':$' | wc -l`
	if [ -n "$nb_nodes" ] && [ $nb_nodes -eq $wanted ]; then
		echo "All nodes are now answering to salt pings"
		break
	fi
	MAX_WAIT=`expr $MAX_WAIT - 15`
	if [ $MAX_WAIT -le 0 ]; then
		echo "Only $nb_nodes answering to salt pings out of $wanted after maximum timeout"
		exit 1
	fi
	echo -n "Only $nb_nodes answering to salt pings out of $wanted. Waiting a bit longer ..."
	sleep 15
	echo
done
