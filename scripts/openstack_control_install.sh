#!/bin/bash -x

# setup keystone service
salt -C 'I@keystone:server' state.sls keystone -b 1
# populate keystone services/tenants/admins
salt -C 'I@keystone:client' state.sls keystone.client
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; keystone service-list"

# Install glance and ensure glusterfs clusters
salt -C 'I@glance:server' state.sls glance -b 1
salt -C 'I@glance:server' state.sls glusterfs.client
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; glance image-list"

# Update fernet tokens
salt -C 'I@keystone:server' state.sls keystone

# Install nova service
salt -C 'I@nova:controller' state.sls nova -b 1
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; nova service-list"

# Install cinder service
salt -C 'I@cinder:controller' state.sls cinder -b 1
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; cinder list"

# Install neutron service
salt -C 'I@neutron:server' state.sls neutron -b 1
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron agent-list"

# Install heat service
salt -C 'I@heat:server' state.sls heat -b 1
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; heat resource-type-list"

# Install horizon dashboard
salt -C 'I@horizon:server' state.sls horizon
salt -C 'I@nginx:server' state.sls nginx
