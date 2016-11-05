#!/bin/bash -x

# Install StackLight collectors
salt "*" state.sls collectd
salt "*" state.sls heka

# Update salt-mine metadata definitions
salt "*" state.sls salt.minion.grains
salt "*" mine.flush
salt "*" mine.update

# Update monitoring node with mine metadata
salt -C 'I@heka:aggregator' state.sls collectd,heka
