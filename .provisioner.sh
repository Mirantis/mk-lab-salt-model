#!/usr/bin/env bash

# generate and validate reclass-salt-model
# expected to be executed in isolated environment, ie: docker

export LC_ALL=C

set -e
if [[ $DEBUG =~ ^(True|true|1|yes)$ ]]; then
    set -x
fi

test -e *.env && source *.env

test -e /usr/bin/salt-master || {
  apt-get update
  apt-get install --allow-unauthenticated -y wget
  echo 'deb [arch=amd64] http://apt.tcpcloud.eu/nightly xenial main tcp tcp-salt' > /etc/apt/sources.list
  echo 'deb http://repo.saltstack.com/apt/ubuntu/ubuntu14/2016.3/ trusty main' > /etc/apt/sources.list.d/salt.list
  wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -
  wget -O - http://repo.saltstack.com/apt/ubuntu/ubuntu14/2016.3/SALTSTACK-GPG-KEY.pub | apt-key add -
  apt-get update
  apt-get -qqq install --allow-unauthenticated -y python-pip salt-master curl reclass salt-formula-*
}


## Overrideable options
RECLASS_ROOT=${RECLASS_ROOT:-$(pwd)}
SALT_OPTS="${SALT_OPTS} --retcode-passthrough --force-color"

## Functions
log_info() {
    echo "[INFO] $*"
}

log_err() {
    echo "[ERROR] $*" >&2
}

_atexit() {
    RETVAL=$?
    trap true INT TERM EXIT

    if [ $RETVAL -ne 0 ]; then
        log_err "Execution failed"
    else
        log_info "Execution successful"
    fi

    return $RETVAL
}


## Main
trap _atexit INT TERM EXIT


log_info "System configuration"
mkdir -p /root/.ssh
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts


log_info "Uploading reclass"
mkdir -p /srv/salt/reclass
cp -a /tmp/reclass/* /srv/salt/reclass
cp -a /tmp/reclass/.git /srv/salt/reclass


log_info "Setting up Salt master"
# TODO: remove grains.d hack when fixed in formula
# TODO: replace with https://github.com/tcpcloud/salt-bootstrap-test
mkdir -p /etc/salt/grains.d && touch /etc/salt/grains.d/dummy
[ ! -d /etc/salt/pki/minion ] && mkdir -p /etc/salt/pki/minion
[ ! -d /etc/salt/master.d ] && mkdir -p /etc/salt/master.d || true
cat <<-'EOF' > /etc/salt/master.d/master.conf
  file_roots:
    base:
    - /usr/share/salt-formulas/env
  pillar_opts: False
  open_mode: True
  reclass: &reclass
    storage_type: yaml_fs
    inventory_base_uri: /srv/salt/reclass
  ext_pillar:
    - reclass: *reclass
  master_tops:
    reclass: *reclass
EOF


log_info "Setting up reclass"
[ -d /srv/salt/reclass/classes/service ] || mkdir -p /srv/salt/reclass/classes/service || true
for i in /usr/share/salt-formulas/reclass/service/*; do
  [ -e /srv/salt/reclass/classes/service/$(basename $i) ] || ln -s $i /srv/salt/reclass/classes/service/$(basename $i)
done

[ ! -d /etc/reclass ] && mkdir /etc/reclass || true
cat <<-'EOF' > /etc/reclass/reclass-config.yml
  storage_type: yaml_fs
  pretty_print: True
  output: yaml
  inventory_base_uri: /srv/salt/reclass
EOF






cd /srv/salt/reclass

# TODO: remove filter for full-scale
# TODO: if branch/PR test only models modified
for i in $(ls /srv/salt/reclass/nodes/control |xargs -i{} basename {} .yml | egrep full-scale); do
  echo -e "\n\n\n\n#####################################\n"
  log_info "=========== Testing model $i ==========="
  export MASTER_HOSTNAME=$i
  rm -rf /srv/salt/reclass/nodes/_generated/*

  log_info "Salt master service"
  #DETACH=1 /usr/bin/salt-master &
  /etc/init.d/salt-master restart
  sleep 3

  log_info "Setting up Salt minion"
  apt-get install -y salt-minion
  [ ! -d /etc/salt/minion.d ] && mkdir -p /etc/salt/minion.d || true
  cat <<-EOF > /etc/salt/minion.d/minion.conf
    id: ${MASTER_HOSTNAME}
    master: localhost
EOF


  log_info "Verify Salt master pillar"
  reclass-salt -p ${MASTER_HOSTNAME}
  salt-call ${SALT_OPTS} state.show_top

  log_info "Generate node definitions"
  salt-call ${SALT_OPTS} state.sls reclass.storage.node -linfo


  log_info "Verify individual nodes pillar"
  NODES=$(ls /srv/salt/reclass/nodes/_generated)
  for node in ${NODES}; do
      node=$(basename $node .yml)
      echo -e "\n\n\n\n#####################################\n"
      log_info "Verifying node ${node}"
      reclass-salt -p ${node}
      salt-call ${SALT_OPTS} --id=${node} state.show_lowstate -linfo
  done
done
