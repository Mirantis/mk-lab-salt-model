This cluster model is aligned to use with 'system' layer from https://github.com/Mirantis/reclass-system-salt-model

Lab description:

* Baremetal nodes::
3 x baremetal nodes for virtualised control plane:
 - kvm01
 - kvm02
 - kvm03
2 x baremetal compute nodes (/dev/sdb required for 'cinder-volumes' VG):
 - cmp01
 - cmp02
1 x baremetal gateway node:
 - gtw01

* Virtual nodes running on kvm* nodes::
3 x VM control nodes:
 - ctl01
 - ctl02
 - ctl03
3 x VM database nodes:
 - dbs01
 - dbs02
 - dbs03
3 x VM messaging nodes:
 - msg01
 - msg02
 - msg03
2 x VM proxy nodes:
 - prx01
 - prx02
9 x VM nodes for stacklight services:
 - log01
 - log02
 - log03
 - mon01
 - mon02
 - mon03
 - mtr01
 - mtr02
 - mtr03

* Salt-master node (can be baremetal or VM)::
 - cfg01


Pre-condition (TODO for salt.control)::
 - LVM volume group 'cinder-volumes' should be added on the ctl* nodes.
