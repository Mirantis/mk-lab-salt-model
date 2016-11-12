#!/usr/bin/env bash

# generate and validate reclass-salt-model
# expected to be executed in isolated environment, ie: docker

export LC_ALL=C

set -e
if [[ $DEBUG =~ ^(True|true|1|yes)$ ]]; then
    set -x
fi

# source .kitchen.env and possibly others
#shopt -u dotglob
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


# FIXME, TEMPORARY WORKROUND, to avoid salt-* from tcpcloud repos in (extra apt component)
echo 'deb http://repo.saltstack.com/apt/ubuntu/ubuntu14/2016.3/ trusty main' > /etc/apt/sources.list.d/salt.list
curl -sKL http://repo.saltstack.com/apt/ubuntu/ubuntu14/2016.3/SALTSTACK-GPG-KEY.pub | apt-key add -
apt-get update || log_err "Got some issues on apt update"
apt-get clean
apt-get -qqq install --allow-change-held-packages --allow-unauthenticated -y salt-master salt-minion || log_err "Some formulas failed to install" #reclass # python-pip #salt-formula-*

## Overrideable options
RECLASS_ROOT=${RECLASS_ROOT:-$(pwd)}
SALT_OPTS="${SALT_OPTS} --retcode-passthrough --force-color"


log_info "System configuration"
mkdir -p /root/.ssh
ssh-keyscan -t rsa github.com > /root/.ssh/known_hosts
ssh-keyscan -t rsa github.com > ~/.ssh/known_hosts
mkdir -p /srv/salt/reclass/classes/service


log_info "Uploading local reclass"
test -e /tmp/reclass/.git && {
  test -e /srv/salt/reclass/.git && git pull -r || git clone /tmp/reclass /srv/salt/reclass
} || {
  cp -a /tmp/reclass/scripts /srv/salt/reclass || echo "X"
  cp -a /tmp/reclass/classes /srv/salt/reclass || echo "X"
  cp -a /tmp/reclass/nodes /srv/salt/reclass || echo "X"
  cp -a /tmp/reclass/.git /srv/salt/reclass || echo "X"
}


log_info "Setting up Salt master, minion"
pgrep salt-master | xargs -i{} sudo kill -9 {}
pgrep salt-minion | xargs -i{} sudo kill -9 {}
cd /srv/salt/reclass;
export RECLASS_ADDRESS=${RECLASS_ADDRESS:-$(git remote get-url origin)}
#HOSTNAME=$(${MASTER_HOSTNAME} | awk -F. '{print $1}')
#DOMAIN=$(${MASTER_HOSTNAME}   | awk -F. '{print $ARGV[1..]}')
curl -skL "https://raw.githubusercontent.com/tcpcloud/salt-bootstrap-test/master/bootstrap.sh" > bootstrap.sh; chmod +x *.sh;
SALT_MASTER=localhost MINION_ID=${MASTER_HOSTNAME} ./bootstrap.sh master || log_err "Bootstrap.sh exited with: $?."


log_info "Clean up generated"
cd /srv/salt/reclass
rm -rf /srv/salt/reclass/nodes/_generated/*
rm  -f /srv/salt/reclass/nodes/${MASTER_HOSTNAME}.yml # new model uses ./control/cfg*.yml


log_info "Re/starting salt services"
service salt-master restart #; sleep 10
service salt-minion restart

log_info "Showing system info and metadata ..."
salt-call --no-color grains.items
salt-call --no-color pillar.data


# Init salt master
log_info "Runing saltmaster states"
if [[ $MASTER_INIT_STATES =~ ^(True|true|1|yes)$ ]]; then
  salt-call ${SALT_OPTS} state.sls reclass -linfo || log_err "Some states failed to apply"
  salt-call ${SALT_OPTS} state.sls salt.master.service -l info
  git reset # otherwise next step fail to update reclass data dir
  salt-call ${SALT_OPTS} state.sls salt.master -l info || log_err "Some states failed to apply"
else
  salt-call ${SALT_OPTS} state.sls reclass.storage.node -linfo #--state-output=terse
fi


log_info "Fetch dependencies"
if [[ $MASTER_INIT_STATES =~ ^(True|true|1|yes)$ ]]; then
  salt-call ${SALT_OPTS} state.sls salt -linfo || log_err "Some states failed to apply"
  sed -i 's/^master:.*/master: localhost/' /etc/salt/minion.d/minion.conf
else
  # install all formulas, for quick check only (fast, tested with FORMULA_SOURCE=pkg)
  apt-get update || log_err "Got some issues on apt update"
  apt-get clean
  apt-get install -y --fix-missing salt-formula-* || log_err "Some formulas failed to install"
fi


# SERVICE LINKING (above salt state call may fail to link service if repository contain uncommitted changes)
mkdir -p /srv/salt/reclass/service
# for formulas from git repos
for service in $(ls /usr/share/salt-formulas/env/_formulas); do
  [ -e /srv/salt/reclass/service/$service ] || \
    { ln -vs /usr/share/salt-formulas/env/_formulas/$service/metadata/service /srv/salt/reclass/classes/service/$service \
    || log_info "$service does not have a service definitions"
  }
done
# for formulas from packages
for service in $(ls /usr/share/salt-formulas/reclass/service); do
  [ -e /srv/salt/reclass/classes/service/$service ]  || \
    { ln -vs /usr/share/salt-formulas/reclass/service/$service /srv/salt/reclass/classes/service/$service \
    || log_info "$service service definition already exist"
  }
done


log_info "Verify Salt master"
service salt-minion restart
salt-call ${SALT_OPTS} saltutil.sync_all
reclass-salt -p ${MASTER_HOSTNAME}
salt-call ${SALT_OPTS} state.show_top


log_info "Verify model nodes"
NODES=$(ls /srv/salt/reclass/nodes/_generated)
for node in ${NODES}; do
    node=$(basename $node .yml)
    log_info "\n\n-------------------------------------------------------------------------------------------------------"
    log_info "Verifying node ${node}"
    reclass-salt -p ${node}
    salt-call ${SALT_OPTS} --id=${node} state.show_lowstate -linfo --state-output=terse
done
