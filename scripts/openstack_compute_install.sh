#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Configure compute nodes
salt $SALT_OPTS "cmp*" state.apply
salt $SALT_OPTS "cmp*" state.apply

# Create subnet
salt $SALT_OPTS 'ctl01*' cmd.run ". /root/keystonerc; neutron net-create net1; neutron subnet-create --name subnet1 net1 192.168.32.0/24 ; neutron net-list"

# Provision opencontrail virtual routers
hosts=(`salt-call pillar.get linux:network:host | egrep 'cmp0.*:' | sed -e 's/  *//' -e 's/://'`)
vip=`salt-call pillar.get _param:cluster_vip_address | grep '^ ' | sed -e 's/  *//'`
nb=`expr ${#hosts[@]} - 1`
for i in $(seq 0 $nb); do
	h=${hosts[$i]}
	ip=`salt-call pillar.get linux:network:host:${h}:address | grep '^ ' | sed -e 's/  *//'`
	salt $SALT_OPTS -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_vrouter.py --host_name $h --host_ip $ip --api_server_ip $vip --oper add --admin_user admin --admin_password workshop --admin_tenant_name admin"
done
salt $SALT_OPTS 'cmp*' cmd.run "ip link set up eth1"﻿⁠⁠⁠⁠

# Reboot compute nodes
salt $SALT_OPTS "cmp*" system.reboot

while true; do
	salt $SALT_OPTS '*' test.ping | grep -q Minion
	if [ $? -ne 0 ]; then
		break
	fi
	echo -n "Waiting for compute nodes to answer salt pings ..."
	sleep 10
	echo
done
