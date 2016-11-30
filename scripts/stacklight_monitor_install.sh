#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Start by flusing Salt Mine to make sure it is clean
salt "*" mine.flush

# Install StackLight services, and gather the Collectd and Heka metadata
salt "*" state.sls collectd
salt "*" state.sls heka

# Gather the Grafana metadata as grains
salt -C 'I@grafana:collector' state.sls grafana.collector

# Update Salt Mine
salt "*" state.sls salt.minion.grains
salt "*" saltutil.refresh_modules
salt "*" mine.update

sleep 5

# Update Heka
salt -C 'I@heka:aggregator:enabled:True or I@heka:remote_collector:enabled:True' state.sls heka

# Update Collectd
salt -C 'I@collectd:remote_client:enabled:True' state.sls collectd

# Update Nagios
salt -C 'I@nagios:server' state.sls nagios

# The following is only applied when Nagios is deployed in cluster: stop Nagios
# on monitoring nodes (b/c package starts it by default), then start Nagios
# where the VIP is running
salt -C 'I@nagios:server:automatic_starting:False' service.stop nagios3
salt -G 'ipv4:172.16.10.253' service.start nagios3

# Finalize the configuration of Grafana (add the dashboards...)
salt -C 'I@grafana:client' state.sls grafana.client
