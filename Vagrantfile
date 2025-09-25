# -*- mode: ruby -*-
# vi: set ft=ruby :

# Переменные конфигурации
NETWORK_BASE = "192.168.56"
STORAGE_IP = "#{NETWORK_BASE}.50"
CONTROLPLANE_IP = "#{NETWORK_BASE}.10"

Vagrant.configure("2") do |config|
  # Используем образ Ubuntu 20.04
  config.vm.box = "ubuntu/focal64"
  config.vm.synced_folder "infrastructure/vagrant/scripts", "/vagrant/scripts", type: "rsync"
  config.vm.synced_folder "infrastructure", "/vagrant/infrastructure", type: "rsync"

  config.vm.define "storage" do |storage|
    storage.vm.hostname = "storage"
    storage.vm.network "private_network", ip: STORAGE_IP
    storage.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "1"
      vb.linked_clone = true
    end
    storage.vm.provision "shell", inline: <<-SHELL
      sudo apt-get update
      sudo apt-get install -y nfs-kernel-server
      sudo mkdir -p /srv/nfs/kubedata
      sudo chown -R nobody:nogroup /srv/nfs/kubedata
      sudo chmod 755 /srv/nfs/kubedata
      echo "/srv/nfs/kubedata #{NETWORK_BASE}.0/24(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534)" | sudo tee /etc/exports
      sudo exportfs -ra
      sudo systemctl enable --now nfs-kernel-server
      # Проверка готовности сервиса
      sudo systemctl is-active --quiet nfs-kernel-server && echo "NFS server ready"
    SHELL
  end

  # Настройка мастер-ноды
  config.vm.define "controlplane" do |master|
    master.vm.hostname = "controlplane"
    master.vm.network "private_network", ip: CONTROLPLANE_IP
    master.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = "2"
      vb.linked_clone = true
    end
    master.vm.provision "shell", path: "infrastructure/vagrant/scripts/common.sh"
    master.vm.provision "shell", path: "infrastructure/vagrant/scripts/master.sh"
    master.vm.provision "shell", inline: <<-SHELL
      sudo cp /etc/kubernetes/admin.conf /vagrant/infrastructure/vagrant/scripts/config
    SHELL

    master.trigger.after :up do |trigger|
      trigger.run = {inline: "mkdir -p $HOME/.kube"}
      trigger.run = {inline: "bash -c 'cp ./infrastructure/vagrant/scripts/config $HOME/.kube/config'"}
    end
  end

  # Настройка рабочих нод (в данном примере 2)
  (1..2).each do |i|
    config.vm.define "node0#{i}" do |worker|
      worker.vm.hostname = "node0#{i}"
      worker.vm.network "private_network", ip: "#{NETWORK_BASE}.#{10 + i}"
      worker.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
        vb.cpus = "1"
        vb.linked_clone = true
      end
      worker.vm.provision "shell", path: "infrastructure/vagrant/scripts/common.sh"
      worker.vm.provision "shell", path: "infrastructure/vagrant/scripts/join.sh"
      worker.vm.provision "shell", inline: <<-SHELL
        sudo apt-get update && sudo apt-get install -y nfs-common
      SHELL
    end
  end

end