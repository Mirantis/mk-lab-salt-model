#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Configure compute nodes
salt "cmp*" state.apply
salt "cmp*" state.apply

# Provision opencontrail virtual routers
salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_vrouter.py --host_name cmp01 --host_ip 172.16.10.105 --api_server_ip 172.16.10.254 --oper add --admin_user admin --admin_password workshop --admin_tenant_name admin"

# Reboot compute nodes
salt "cmp*" system.reboot

sleep 30
