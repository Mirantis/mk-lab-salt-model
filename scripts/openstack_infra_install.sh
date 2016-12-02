#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Install keepaliveds
salt $SALT_OPTS -C 'I@keepalived:cluster' state.sls keepalived -b 1
# Check the VIPs
salt $SALT_OPTS -C 'I@keepalived:cluster' cmd.run "ip a | grep 172.16.10.2"

# Install gluster
salt $SALT_OPTS -C 'I@glusterfs:server' state.sls glusterfs.server.service
salt $SALT_OPTS -C 'I@glusterfs:server' state.sls glusterfs.server.setup -b 1
# Check the gluster status
salt $SALT_OPTS -C 'I@glusterfs:server' cmd.run "gluster peer status; gluster volume status" -b 1

# Install rabbitmq
salt $SALT_OPTS -C 'I@rabbitmq:server' state.sls rabbitmq
# Check the rabbitmq status
salt $SALT_OPTS -C 'I@rabbitmq:server' cmd.run "rabbitmqctl cluster_status"

# Install galera
salt $SALT_OPTS -C 'I@galera:master' state.sls galera
salt $SALT_OPTS -C 'I@galera:slave' state.sls galera
# Check galera status
salt $SALT_OPTS -C 'I@galera:master' mysql.status | egrep -A1 'wsrep_cluster_size|addresses'
salt $SALT_OPTS -C 'I@galera:slave' mysql.status | egrep -A1 'wsrep_cluster_size|addresses'

# Install haproxy
salt $SALT_OPTS -C 'I@haproxy:proxy' state.sls haproxy
salt $SALT_OPTS -C 'I@haproxy:proxy' service.status haproxy
salt $SALT_OPTS -I 'haproxy:proxy' service.restart rsyslog

# Install memcached
salt $SALT_OPTS -C 'I@memcached:server' state.sls memcached
salt $SALT_OPTS -C 'I@memcached:server' service.status memcached
