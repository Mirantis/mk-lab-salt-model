# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

$script = <<SCRIPT
echo "deb [arch=amd64] http://apt.tcpcloud.eu/nightly/ trusty main security extra tcp tcp-salt" > /etc/apt/sources.list
wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -
apt-get update
apt-get install -y salt-minion
cat << "EOF" >> /etc/salt/minion.d/minion.conf
id: {{x}}.mk20-lab-basic.local
master: 192.168.10.100
EOF
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/trusty64"

  config.vm.provider "virtualbox" do |vb|
     # Display the VirtualBox GUI when booting the machine
     vb.gui = true
  
     # Customize the amount of memory on the VM:
     vb.memory = "4096"
  end

  config.vm.define "cfg01" do |cfg01|
    cfg01.vm.box = "ubuntu/xenial64"
    cfg01.vm.network "private_network", ip: "172.16.10.100"
    cfg01.vm.network "private_network", ip: "192.168.10.100"
  end

  config.vm.define "ctl01" do |ctl01|
    ctl01.vm.box = config.vm.box
    ctl01.vm.provision "shell", inline: $script.sub(/{{x}}/, "ctl01")
    ctl01.vm.network "private_network", ip: "172.16.10.101"
    ctl01.vm.network "private_network", ip: "192.168.10.101"
  end

  config.vm.define "ctl02" do |ctl02|
    ctl02.vm.box = config.vm.box
    ctl02.vm.provision "shell", inline: $script.sub(/{{x}}/, "ctl02")
    ctl02.vm.network "private_network", ip: "172.16.10.102"
    ctl02.vm.network "private_network", ip: "192.168.10.102"
  end

  config.vm.define "ctl03" do |ctl03|
    ctl03.vm.box = config.vm.box
    ctl03.vm.provision "shell", inline: $script.sub(/{{x}}/, "ctl03")
    ctl03.vm.network "private_network", ip: "172.16.10.103"
    ctl03.vm.network "private_network", ip: "192.168.10.103"
  end

  config.vm.define "cmp01" do |cmp01|
    cmp01.vm.box = config.vm.box
    cmp01.vm.provision "shell", inline: $script.sub(/{{x}}/, "cmp01")
    cmp01.vm.network "private_network", ip: "172.16.10.105"
    cmp01.vm.network "private_network", ip: "192.168.10.105"
  end

end
