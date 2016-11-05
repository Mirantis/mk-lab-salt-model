#!/bin/bash

# StackLight services
salt -C 'I@elasticsearch:server' state.sls elasticsearch -b 1
salt -C 'I@influxdb:server' state.sls influxdb -b 1
salt -C 'I@kibana:server' state.sls kibana
salt -C 'I@grafana:server' state.sls grafana
