#!/bin/bash -x

# Install StackLight collectors
salt "*" state.sls collectd
salt "*" state.sls heka

# Update salt-mine metadata definitions
salt "*" state.sls salt.minion.grains
salt "*" mine.flush
salt "*" saltutil.refresh_modules
salt "*" mine.update

sleep 5

# Update monitoring node with mine metadata
salt -C 'I@heka:aggregator' state.sls collectd,heka

# Install Nagios once alarms are stored in Salt Mine
salt -C 'I@nagios:server' state.sls nagios
