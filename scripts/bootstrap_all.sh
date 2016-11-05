#!/bin/bash

./fuel_config_verify.sh
./fuel_infra_install.sh
./openstack_infra_install.sh
./openstack_control_install.sh
./opencontrail_control_install.sh
./stacklight_monitor_install.sh
./openstack_compute_install.sh
./stacklight_infra_install.sh
