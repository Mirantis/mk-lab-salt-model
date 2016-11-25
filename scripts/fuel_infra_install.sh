#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Refresh salt master config
salt -C 'I@salt:master' state.sls salt.master,reclass

# Refresh minion's pillar data
salt '*' saltutil.refresh_pillar

# Sync all salt resources
salt '*' saltutil.sync_all

sleep 5

# Initialize the loopback device for LVM on the Cinder volume nodes
# This should happen before applying the Linux formula which is in charge of
# creating the LVM physical and virtual groups.
salt -C 'I@cinder:volume:loopback_device' state.sls cinder.device_setup

# Bootstrap all nodes
salt "*" state.sls linux,openssh,salt.minion,ntp
