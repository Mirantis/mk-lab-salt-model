#!/usr/bin/env bash

# generate and validate reclass-salt-model
# expected to be executed in isolated environment, ie: docker

if [[ $DEBUG =~ ^(True|true|1|yes)$ ]]; then
    set -x
fi

# source .kitchen.env and possibly others
# shopt -u dotglob
test -e /*.env && {
  source /*.env
}


## Functions
log_info() {
    echo "[INFO] $*"
}

log_err() {
    echo "[ERROR] $*" >&2
}

#_atexit() {
#    RETVAL=$?
#    trap true INT TERM EXIT
#
#    if [ $RETVAL -ne 0 ]; then
#        log_err "Execution failed"
#    else
#        log_info "Execution successful"
#    fi
#
#    return $RETVAL
#}


## Main
#trap _atexit INT TERM EXIT
main() {

  export LC_ALL=C

  set -e

  which salt-minion salt-master || {
    apt-get update || log_err "APT update failed"
    apt-get clean
    apt-get -qqq install --allow-change-held-packages --allow-unauthenticated -y salt-master salt-minion python-psutil
  }

  ## Options
  RECLASS_ROOT=${RECLASS_ROOT:-$(pwd)}
  SALT_OPTS="${SALT_OPTS:- --state-output=changes --state-verbose=false --retcode-passthrough --force-color -lerror}"


  log_info "System configuration"
  mkdir -p /srv/salt/reclass/classes/service
  mkdir -p /root/.ssh
  grep github.com /root/.ssh/known_hosts || {
    ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
    ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts
  }


  log_info "Uploading local reclass"
  #test -e /tmp/reclass/.git && {
    #log_info ".. as git clone"
    #test -e /srv/salt/reclass/.git && git pull -r || git clone /tmp/reclass /srv/salt/reclass
  #} || {
    log_info ".. as static folders"
    cp -fa /tmp/reclass/scripts /srv/salt/reclass || echo "X"
    cp -fa /tmp/reclass/classes /srv/salt/reclass || echo "X"
    cp -fa /tmp/reclass/nodes /srv/salt/reclass || echo "X"
    cp -fa /tmp/reclass/.git /srv/salt/reclass || echo "X"
  #}


  log_info "Setting up Salt master, minion"
  pgrep salt-master | xargs -i{} sudo kill -9 {}
  pgrep salt-minion | xargs -i{} sudo kill -9 {}
  cd /srv/salt/reclass;
  export RECLASS_ADDRESS=${RECLASS_ADDRESS:-$(git remote get-url origin)}
  #HOSTNAME=$(${MASTER_HOSTNAME} | awk -F. '{print $1}')
  #DOMAIN=$(${MASTER_HOSTNAME}   | awk -F. '{print $ARGV[1..]}')
  test -e bootstrap.sh || \
    curl -skL "https://raw.githubusercontent.com/tcpcloud/salt-bootstrap-test/master/bootstrap.sh" > bootstrap.sh; chmod +x *.sh;
  test -e bootstrap.sh.lock || \
    SALT_MASTER=localhost MINION_ID=${MASTER_HOSTNAME} ./bootstrap.sh master && touch bootstrap.sh.lock || log_err "Bootstrap.sh exited with: $?."


  log_info "Clean up generated"
  cd /srv/salt/reclass
  rm -rf /srv/salt/reclass/nodes/_generated/*
  rm  -f /srv/salt/reclass/nodes/${MASTER_HOSTNAME}.yml # new model uses ./control/cfg*.yml


  log_info "Re/starting salt services"
  service salt-master restart
  service salt-minion restart
  sleep 10
}

# Init salt master
init_salt_master() {
  log_info "Runing saltmaster states"
  salt-call saltutil.sync_all
  if [[ $MASTER_INIT_STATES =~ ^(True|true|1|yes)$ ]]; then
    salt-call ${SALT_OPTS} state.sls salt.master
  else
    salt-call ${SALT_OPTS} state.sls salt.master.env
    salt-call ${SALT_OPTS} state.sls salt.master.pillar   pillar='{"reclass":{"storage":{"enabled":"False"}}}'
                                                          # sikp reclass data dir states
                                                          # in order to avoid pull from configured repo/branch
    salt-call ${SALT_OPTS} state.sls reclass.storage.node
  fi

  service salt-minion restart
  salt-call ${SALT_OPTS} saltutil.sync_all

  # Instantinate Salt Master
  if [[ $MASTER_INIT_STATES =~ ^(True|true|1|yes)$ ]]; then
  #  salt-call ${SALT_OPTS} state.sls reclass
    salt-call ${SALT_OPTS} state.sls salt
    sed -i 's/^master:.*/master: localhost/' /etc/salt/minion.d/minion.conf
  fi
}


function verify_salt_master() {
  log_info "Verify Salt master"
  reclass-salt -p ${MASTER_HOSTNAME}
  salt-call ${SALT_OPTS} --id=${MASTER_HOSTNAME} state.show_lowstate
  salt-call ${SALT_OPTS} --id=${MASTER_HOSTNAME} grains.item roles
  #salt-call --no-color grains.items
  #salt-call --no-color pillar.data 
}


function verify_salt_minions() {
  log_info "Verify nodes"
  NODES=$(ls /srv/salt/reclass/nodes/_generated)
  for node in ${NODES}; do
      node=$(basename $node .yml)
      log_info "\n\n-------------------------------------------------------------------------------------------------------"
      log_info "Verifying node ${node}"
      reclass-salt -p ${node}
      salt-call ${SALT_OPTS} --id=${node} state.show_lowstate
      salt-call ${SALT_OPTS} --id=${node} grains.item roles
  done
}


# detect if file is being sourced
[[ "$0" != "$BASH_SOURCE"  ]] || {
  main
  init_salt_master
  verify_salt_master
  verify_salt_minions
}
