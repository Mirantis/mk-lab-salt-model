#!/bin/bash -x

# Refresh salt master config
salt -C 'I@salt:master' state.sls salt.master,reclass

# Refresh minion's pillar data
salt '*' saltutil.refresh_pillar

# Bootstrap all nodes
salt "*" state.sls linux,openssh,salt.minion,ntp
