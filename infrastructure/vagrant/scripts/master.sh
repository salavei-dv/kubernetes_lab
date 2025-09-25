#!/bin/bash

# Инициализация кластера
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.56.10
# sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.56.10

# Настройка kubectl для пользователя vagrant
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

# Установка сетевого плагина
# kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
# sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
sudo KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -k /vagrant/infrastructure/network/flannel-config

# Генерация команды для присоединения рабочих узлов
echo "sudo $(sudo kubeadm token create --print-join-command)" > /vagrant/infrastructure/vagrant/scripts/join.sh
chmod +x /vagrant/infrastructure/vagrant/scripts/join.sh
