#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

# Install keepaliveds
salt -C 'I@keepalived:cluster' state.sls keepalived -b 1
# Check the VIPs
salt -C 'I@keepalived:cluster' cmd.run "ip a | grep 172.16.10.2"

# Install gluster
salt -C 'I@glusterfs:server' state.sls glusterfs.server.service
salt -C 'I@glusterfs:server' state.sls glusterfs.server.setup -b 1
# Check the gluster status
salt -C 'I@glusterfs:server' cmd.run "gluster peer status; gluster volume status" -b 1

# Install rabbitmq
salt -C 'I@rabbitmq:server' state.sls rabbitmq
# Check the rabbitmq status
salt -C 'I@rabbitmq:server' cmd.run "rabbitmqctl cluster_status"

# Install galera
salt -C 'I@galera:master' state.sls galera
salt -C 'I@galera:slave' state.sls galera
# Check galera status
salt -C 'I@galera:master' mysql.status | grep -A1 wsrep_cluster_size
salt -C 'I@galera:slave' mysql.status | grep -A1 wsrep_cluster_size

# Install haproxy
salt -C 'I@haproxy:proxy' state.sls haproxy
salt -C 'I@haproxy:proxy' service.status haproxy
salt -I 'haproxy:proxy' service.restart rsyslog

# Install memcached
salt -C 'I@memcached:server' state.sls memcached
