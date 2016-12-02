#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Refresh salt master config
salt $SALT_OPTS -C 'I@salt:master' state.sls salt.master,reclass

# Refresh minion's pillar data
salt $SALT_OPTS '*' saltutil.refresh_pillar

# Sync all salt resources
salt $SALT_OPTS '*' saltutil.sync_all

sleep 5

# Bootstrap all nodes
salt $SALT_OPTS "*" state.sls linux,openssh,salt.minion,ntp
