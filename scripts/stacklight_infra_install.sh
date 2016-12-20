#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

# Install the StackLight backends
salt -C 'I@elasticsearch:server' state.sls elasticsearch.server -b 1
salt -C 'I@influxdb:server' state.sls influxdb -b 1
salt -C 'I@kibana:server' state.sls kibana.server -b 1
salt -C 'I@grafana:server' state.sls grafana.server -b 1
salt -C 'I@nagios:server' state.sls nagios -b 1
salt -C 'I@elasticsearch:client' state.sls elasticsearch.client.service
salt -C 'I@kibana:client' state.sls kibana.client.service
salt -C 'I@kibana:client or I@elasticsearch:client' --async service.restart salt-minion
sleep 10
salt -C 'I@elasticsearch:client' state.sls elasticsearch.client
salt -C 'I@kibana:client' state.sls kibana.client
