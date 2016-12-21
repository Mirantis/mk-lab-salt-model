#!/bin/bash

# Function used to return list of node names according
# to given string parameter match criteria
function get_nodes_names {
	# Enforce 1st parameter availability
	if [ -z "$1" ]; then
		match="[0-9]"
	else
		match="$1"
	fi
	salt-call pillar.get linux:network:host --out key | sed 's/:.*//' | grep "$match"
}

# Function used to wait for node availability
# (aka answering to salt pings)
# 1st parameter (mandatory) is number of nodes to wait for
# 2nd parameter (optional) is nodes names to wait for
#    (* = all nodes is default)
function wait_for {
	# Enforce 1st parameter availability
	if [ -z "$1" ]; then
		echo "wait_for function requires at least 1 parameter"
		return 1
	fi
	if [ "$1" -lt "1" ]; then
		echo "wait_for function requires 1st parameter to be number greater than 0 ($1 invalid)"
		return 1
	fi
	wanted=$1
	nodes=${2:-"*"}
	# Default max waiting time is 5mn
	MAX_WAIT=${MAX_WAIT:-300}
	while true; do
        nb_nodes=$(salt "$nodes" test.ping --out txt | grep -c True)
		if [ -n "$nb_nodes" ] && [ "$nb_nodes" -eq "$wanted" ]; then
			echo "All nodes are now answering to salt pings"
			break
		fi
		MAX_WAIT=$(( MAX_WAIT - 15 ))
		if [ $MAX_WAIT -le 0 ]; then
			echo "Only $nb_nodes answering to salt pings out of $wanted after maximum timeout"
			return 2
		fi
		echo -n "Only $nb_nodes answering to salt pings out of $wanted. Waiting a bit longer ..."
		sleep 15
		echo
	done
	return 0
}
