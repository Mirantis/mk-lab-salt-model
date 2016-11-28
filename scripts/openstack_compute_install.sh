#!/bin/bash -x
exec > >(tee -i /tmp/$(basename $0 .sh)_$(date '+%Y-%m-%d_%H-%M-%S').log) 2>&1

# Configure compute nodes
salt "cmp*" state.apply
salt "cmp*" state.apply

# Reboot compute nodes
salt "cmp*" system.reboot

sleep 30
