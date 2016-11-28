#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

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
# Start manually the services that are bound to the monitoring VIP
salt -G 'ipv4:172.16.10.253' service.start remote_collectd
salt -G 'ipv4:172.16.10.253' service.start remote_collector
salt -G 'ipv4:172.16.10.253' service.start aggregator


# Install Nagios once alarms are stored in Salt Mine
salt -C 'I@nagios:server' state.sls nagios
salt -G 'ipv4:172.16.10.253' service.start nagios3
