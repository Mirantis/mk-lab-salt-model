#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Start by flusing Salt Mine to make sure it is clean
salt $SALT_OPTS "*" mine.flush

# Install StackLight services, and gather the Collectd and Heka metadata
salt $SALT_OPTS "*" state.sls collectd
salt $SALT_OPTS "*" state.sls heka

# Gather the Grafana metadata as grains
salt $SALT_OPTS -C 'I@grafana:collector' state.sls grafana.collector

# Update Salt Mine
salt $SALT_OPTS "*" state.sls salt.minion.grains
salt $SALT_OPTS "*" saltutil.refresh_modules
salt $SALT_OPTS "*" mine.update

sleep 5

# Update Heka
salt $SALT_OPTS -C 'I@heka:aggregator:enabled:True or I@heka:remote_collector:enabled:True' state.sls heka

# Update Collectd
salt $SALT_OPTS -C 'I@collectd:remote_client:enabled:True' state.sls collectd

# Update Nagios
salt $SALT_OPTS -C 'I@nagios:server' state.sls nagios

# Finalize the configuration of Grafana (add the dashboards...)
salt $SALT_OPTS -C 'I@grafana:client' state.sls grafana.client

# The following is only applied when StackLight is deployed in cluster
# Get the StackLight VIP
vip=$(salt-call pillar.data _param:stacklight_monitor_address --out key|grep _param: |awk '{print $2}')
vip=${vip:=172.16.10.253}

# Start manually the services that are bound to the monitoring VIP
salt $SALT_OPTS -G "ipv4:$vip" service.start remote_collectd
salt $SALT_OPTS -G "ipv4:$vip" service.start remote_collector
salt $SALT_OPTS -G "ipv4:$vip" service.start aggregator

# Stop Nagios on monitoring nodes (b/c package starts it by default), then
# start Nagios where the VIP is running.
salt $SALT_OPTS -C 'I@nagios:server:automatic_starting:False' service.stop nagios3
salt $SALT_OPTS -G "ipv4:$vip" service.start nagios3
