#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

CWD="$(dirname "$(readlink -f "$0")")"

# Import common functions
COMMONS=$CWD/common_functions.sh
if [ ! -f "$COMMONS" ]; then
	echo "File $COMMONS does not exist"
	exit 1
fi
. "$COMMONS"

# Install opencontrail database services
salt -C 'I@opencontrail:database' state.sls opencontrail.database -b 1
# Install opencontrail control services
salt -C 'I@opencontrail:control' state.sls opencontrail -b 1

# Provision opencontrail control services
hosts=($(get_nodes_names "ctl[0-9]"))
vip=$(salt-call pillar.get _param:cluster_vip_address | grep '^ ' | sed -e 's/  *//')
nb=$(( ${#hosts[@]} - 1 ))
for i in $(seq 0 $nb); do
	h=${hosts[$i]}
	ip=$(salt-call pillar.get linux:network:host:"${h}":address | grep '^ ' | sed -e 's/  *//')
	salt -C 'I@opencontrail:control:id:1' cmd.run "/usr/share/contrail-utils/provision_control.py --api_server_ip $vip --api_server_port 8082 --host_name $h --host_ip $ip --router_asn 64512 --admin_password workshop --admin_user admin --admin_tenant_name admin --oper add"
done

# Test opencontrail
salt -C 'I@opencontrail:control' cmd.run "contrail-status"
salt -C 'I@keystone:server' cmd.run ". /root/keystonerc; neutron net-list; nova net-list"
