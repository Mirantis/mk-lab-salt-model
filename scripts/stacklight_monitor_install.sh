#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

# Start by flusing Salt Mine to make sure it is clean
# Also clean-up the grains files to make sure that we start from a clean state
salt "*" mine.flush
salt "*" file.remove /etc/salt/grains.d/collectd
salt "*" file.remove /etc/salt/grains.d/grafana
salt "*" file.remove /etc/salt/grains.d/heka
salt "*" file.remove /etc/salt/grains

# Install collectd and heka services on the nodes, this will also generate the
# metadata that goes into the grains and eventually into Salt Mine
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

# Update collectd
salt -C 'I@collectd:remote_client:enabled:True' state.sls collectd

# Update Nagios
salt -C 'I@nagios:server' state.sls nagios
# Stop the Nagios service because the package starts it by default and it will
# started later only on the node holding the VIP address
salt -C 'I@nagios:server' service.stop nagios3

# Finalize the configuration of Grafana (add the dashboards...)
salt -C 'I@grafana:client' state.sls grafana.client.service
salt -C 'I@grafana:client' --async service.restart salt-minion; sleep 10
salt -C 'I@grafana:client' state.sls grafana.client

# Get the StackLight monitoring VIP addres
vip=$(salt-call pillar.data _param:stacklight_monitor_address --out key|grep _param: |awk '{print $2}')
vip=${vip:=172.16.10.253}

# (re)Start manually the services that are bound to the monitoring VIP
salt -G "ipv4:$vip" service.restart remote_collectd
salt -G "ipv4:$vip" service.restart remote_collector
salt -G "ipv4:$vip" service.restart aggregator
salt -G "ipv4:$vip" service.restart nagios3
