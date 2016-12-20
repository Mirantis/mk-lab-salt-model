#!/bin/bash -x
exec > >(tee -i /tmp/"$(basename "$0" .sh)"_"$(date '+%Y-%m-%d_%H-%M-%S')".log) 2>&1

# Refresh salt master config
salt -C 'I@salt:master' state.sls salt.master,reclass

# Refresh minion's pillar data
salt '*' saltutil.refresh_pillar

# Sync all salt resources
salt '*' saltutil.sync_all

sleep 5

# Bootstrap all nodes
salt "*" state.sls linux,openssh,salt.minion,ntp,rsyslog
