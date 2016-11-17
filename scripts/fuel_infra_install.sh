#!/bin/bash -x

# Refresh salt master config
salt -C 'I@salt:master' state.sls salt.master,reclass

# Refresh minion's pillar data
salt '*' saltutil.refresh_pillar

# Sync states and modules
salt '*' saltutil.sync_states
salt '*' saltutil.sync_modules

sleep 5

# Bootstrap all nodes
salt "*" state.sls linux,openssh,salt.minion,ntp
