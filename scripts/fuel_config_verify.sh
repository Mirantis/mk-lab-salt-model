#!/bin/bash

# Verify that Salt master is correctly bootstrapped
salt-key
reclass-salt --top

# Verify that Salt minions are responding and the same version as master
salt-call --version
salt '*' test.version
