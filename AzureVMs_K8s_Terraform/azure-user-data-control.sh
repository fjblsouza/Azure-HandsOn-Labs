#! /bin/bash

# On all nodes, set up containerd. You will need to load some kernel modules and modify some system settings as part of this process.
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

# On all nodes, disable swap.
sudo swapoff -a

#Disable firewall
sudo ufw disable

# On all nodes, install kubeadm, kubelet, and kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#Note: In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, and it should be created before the curl command.

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install and configure containerd. Note: use the following command "sudo kill -9 $( sudo lsof /var/lib/dpkg/lock-frontend | awk '{ print $2 }' | tail -1 )" if you receive a "E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?" message.
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

#Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

#Enable the kubelet service before running kubeadm
sudo systemctl enable --now kubelet

#On the control plane node only, initialize the cluster and set up kubectl access.

#sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version 1.29.3 --> To run manually into the control VM
#mkdir -p $HOME/.kube --> To run manually into the control VM
#sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config --> To run manually into the control VM
#sudo chown $(id -u):$(id -g) $HOME/.kube/config --> To run manually into the control VM

#Install the Calico network add-on.
#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml --> To run manually into the control VM




