#!/bin/bash

# Install keepaliveds
salt -C 'I@keepalived:cluster' state.sls keepalived -b 1
# Check the VIPs
salt -C 'I@keepalived:cluster' cmd.run "ip a | grep 172.16.10.2"

# Install gluster
salt -C 'I@glusterfs:server' state.sls glusterfs.server.service
salt -C 'I@glusterfs:server' state.sls glusterfs.server.setup -b 1
# Check the gluster status
salt -C 'I@glusterfs:server' cmd.run "gluster peer status; gluster volume status"

# Install rabbitmq
salt -C 'I@rabbitmq:server' state.sls rabbitmq
# Check the rabbitmq status
salt -C 'I@rabbitmq:server' cmd.run "rabbitmqctl cluster_status"

# Install galera
salt -C 'I@galera:master' state.sls galera
salt -C 'I@galera:slave' state.sls galera
# Check galera status
salt -C 'I@galera:master' mysql.status

# Install haproxy
salt -C 'I@haproxy:proxy' state.sls haproxy
salt -C 'I@haproxy:proxy' service.status haproxy

# Install memcached
salt -C 'I@memcached:server' state.sls memcached
