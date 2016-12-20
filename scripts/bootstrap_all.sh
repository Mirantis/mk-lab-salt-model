#!/bin/bash -x

CWD="$(dirname "$(readlink -f "$0")")"

"$CWD"/fuel_config_verify.sh
"$CWD"/fuel_infra_install.sh
"$CWD"/openstack_infra_install.sh
"$CWD"/openstack_control_install.sh
"$CWD"/opencontrail_control_install.sh
"$CWD"/stacklight_infra_install.sh
"$CWD"/openstack_compute_install.sh
"$CWD"/stacklight_monitor_install.sh
