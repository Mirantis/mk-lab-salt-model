====================
Mk20 Labs Salt Model
====================

OpenStack Reclass models for Mk-based cloud for training and development.


New cluster class
=================

A new simple way to model multiple deployments in 1 reclass is now possible by
new top level class *cluster*. This is a major change in model after 1-2 years
using the current *service* and *system* separation and was created to address
needs to clearly support:

* multiple parallel deployments,
* mitigate the need of pregenerated data [cookiecutter],
* unite the large production and small lab models in common format

This approach replaces actual *system/openstack/...* systems. It covers all
current labs, stacklight labs up to the mk22-full-scale production ready
deployments.


Structure
---------

Each deployment is defined in own *cluster* directory
`classes/cluster/<deployment_name>`. Short overview of deployment dir content:

init.yml
  Shared location parameters, all hosts
openstack.yml
  shared OpenStack parameters
openstack-control/compute/database/etc.yml
 defined service clusters
mon.yml
  shared monitoring parameters
monitoring-server/proxy/etc.yml
  defined monitoring clusters/servers

The openstack-config is new cluster role for salt master and is used to define
all nodes and services.

All other systems [ceph/stacklight/mcp] can be setup the same way. With this
setup you have on system level only generic system fragments [not to be
changed too much, better amended per case/pattern] and you have full power to
override/separate services at the cluster level.

This approach basically removes the need for cookiecutter as the common files
contain basically the content of what you would imput to cookiecutter. The
current content of mk-lab-salt-model is basically demo of parallel deployment
models with multiple separate salt-masters defined that reuse the single
model.


Available setups
================


Mk.20 basic testing lab
-----------------------

* 1 config node
* 3 control nodes
* 1 compute node


Mk.20 advanced testing lab
--------------------------

* 1 config node
* 3 control nodes
* 1 compute node
* 1 monitor node


Mk.20 expert testing lab
------------------------

* 1 config node
* 3 control nodes
* 2 compute nodes
* 1 monitor node
* 1 meter node
* 1 log node


Mk.20 basic StackLight lab
--------------------------

* 1 config node
* 3 control nodes
* 1 compute node
* 1 monitor node


Mk.20 advanced StackLight lab
-----------------------------

* 1 config node
* 3 control nodes
* 1 compute node
* 3 monitor nodes


Mk.22 basic testing lab
-----------------------

* 1 config node
* 3 control nodes
* 1 compute node
* 1 monitor node


Mk.22 advanced testing lab
--------------------------

* 1 config node
* 3 control nodes
* 2 compute nodes
* 3 monitoring nodes


Mk.22 full scale lab
--------------------

* 1 config node
* 3 database nodes
* 3 message queue nodes
* 1 openstack dashboard node
* 3 openstack control nodes
* 2 openstack compute nodes
* 3 monitoring nodes
