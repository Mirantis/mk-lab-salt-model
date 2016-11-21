#!/bin/bash -x

# Install opencontrail database services
salt -C 'I@opencontrail:database' state.sls opencontrail.database -b 1
# Install opencontrail control services
salt -C 'I@opencontrail:control' state.sls opencontrail -b 1
# Test opencontrail
salt -C 'I@opencontrail:control' cmd.run "contrail-status"
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron net-list; nova net-list"
