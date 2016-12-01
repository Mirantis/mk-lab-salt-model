#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Install opencontrail database services
salt -C 'I@opencontrail:database' state.sls opencontrail.database -b 1
# Install opencontrail control services
salt -C 'I@opencontrail:control' state.sls opencontrail -b 1

# Provision opencontrail control services
salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl01 --host_ip 172.16.10.101 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl02 --host_ip 172.16.10.102 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip 172.16.10.254 --api_server_port 8082 --host_name ctl03 --host_ip 172.16.10.103 --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"

# Test opencontrail
salt -C 'I@opencontrail:control' cmd.run "contrail-status"
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron net-list; nova net-list"
