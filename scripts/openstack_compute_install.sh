#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Configure compute nodes
salt "cmp*" state.apply
salt "cmp*" state.apply

# Provision opencontrail virtual routers
hosts=(`salt-call pillar.get linux:network:host | egrep 'cmp0.*:' | sed -e 's/  *//' -e 's/://'`)
vip=`salt-call pillar.get _param:cluster_vip_address | grep '^ ' | sed -e 's/  *//'`
nb=`expr ${#hosts[@]} - 1`
for i in $(seq 0 $nb); do
	h=${hosts[$i]}
	ip=`salt-call pillar.get linux:network:host:${h}:address | grep '^ ' | sed -e 's/  *//'`
	salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_vrouter.py --host_name $h --host_ip $ip --api_server_ip $vip --oper add --admin_user admin --admin_password workshop --admin_tenant_name admin"
done

# Reboot compute nodes
salt "cmp*" system.reboot

sleep 30
