#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Install opencontrail database services
salt $SALT_OPTS -C 'I@opencontrail:database' state.sls opencontrail.database -b 1
# Install opencontrail control services
salt $SALT_OPTS -C 'I@opencontrail:control' state.sls opencontrail -b 1

# Provision opencontrail control services
hosts=(`salt-call pillar.get linux:network:host | egrep 'ctl0.*:' | sed -e 's/  *//' -e 's/://'`)
vip=`salt-call pillar.get _param:cluster_vip_address | grep '^ ' | sed -e 's/  *//'`
nb=`expr ${#hosts[@]} - 1`
for i in $(seq 0 $nb); do
	h=${hosts[$i]}
	ip=`salt-call pillar.get linux:network:host:${h}:address | grep '^ ' | sed -e 's/  *//'`
	salt $SALT_OPTS -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip $vip --api_server_port 8082 --host_name $h --host_ip $ip --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
done

# Test opencontrail
salt $SALT_OPTS -C 'I@opencontrail:control' cmd.run "contrail-status"
salt $SALT_OPTS -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron net-list; nova net-list"
