#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# StackLight services
salt -C 'I@elasticsearch:server' state.sls elasticsearch.server -b 1
salt -C 'I@influxdb:server' state.sls influxdb -b 1
salt -C 'I@kibana:server' state.sls kibana.server
salt -C 'I@grafana:server' state.sls grafana.server -b 1

# Gather Grafana dashboards from all nodes
salt -C 'I@grafana:collector' state.sls grafana.collector
salt "*" state.sls salt.minion.grains
salt "*" mine.flush
salt "*" saltutil.refresh_modules
salt "*" mine.update

sleep 5

salt -C 'I@kibana:client' state.sls kibana.client
salt -C 'I@grafana:client' state.sls grafana.client
