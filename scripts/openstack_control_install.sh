#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# setup keystone service
salt $SALT_OPTS -C 'I@keystone:server' state.sls keystone.server -b 1
# populate keystone services/tenants/admins
salt $SALT_OPTS -C 'I@keystone:client' state.sls keystone.client
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; keystone service-list"

# Install glance and ensure glusterfs clusters
salt $SALT_OPTS -C 'I@glance:server' state.sls glance -b 1
salt $SALT_OPTS -C 'I@glance:server' state.sls glusterfs.client
# Update fernet tokens before doing request on keystone server. Otherwise
# you will get an error like:
# "No encryption keys found; run keystone-manage fernet_setup to bootstrap one"
salt $SALT_OPTS -C 'I@keystone:server' state.sls keystone.server
# Install Cirros image
ssh $SSH_OPTS ctl01 "source keystonerc; wget --progress=bar:force http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-i386-disk.img ; glance image-create --name cirros --visibility public --disk-format qcow2 --container-format bare --progress < /root/cirros-0.3.4-i386-disk.img"
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; glance image-list"

# Install nova service
salt $SALT_OPTS -C 'I@nova:controller' state.sls nova -b 1
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; nova service-list"

# Install cinder service
salt $SALT_OPTS -C 'I@cinder:controller' state.sls cinder -b 1
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; cinder list"

# Install neutron service
salt $SALT_OPTS -C 'I@neutron:server' state.sls neutron -b 1
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron agent-list ; neutron net-list ; nova net-list"

# Install heat service
salt $SALT_OPTS -C 'I@heat:server' state.sls heat -b 1
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; heat resource-type-list"

# Install horizon dashboard
salt $SALT_OPTS -C 'I@horizon:server' state.sls horizon
salt $SALT_OPTS -C 'I@nginx:server' state.sls nginx
