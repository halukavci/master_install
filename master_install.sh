#!/bin/bash -i
ip_vals=""
yum update -y
sed -i -e s/enforcing/disabled/g /etc/sysconfig/selinux
sed -i -e s/permissive/disabled/g /etc/sysconfig/selinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
systemctl stop firewalld
systemctl disable firewalld
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
yum -y install ntp epel-release
systemctl start ntpd
systemctl enable ntpd
ntpdate -u -s 10.0.0.24 10.0.0.224
systemctl restart ntpd
ssh-keygen -q -f ~/.ssh/id_rsa -N ""

for var in "$@" 
do 
ssh-copy-id $var
ip_vals="${ip_vals} $var"
#ssh root@$var "bash -s" < node_install.sh
#scp mode_install.sh root@$var:/root
done

yum install git ansible centos-release-scl -y
yum install rh-python36 -y
#scl enable rh-python36 bash
echo 'source /opt/rh/rh-python36/enable' >> ~/.bashrc
easy_install pip
/opt/rh/rh-python36/root/usr/bin/pip3 install jinja2 --upgrade
git clone https://github.com/kubernetes-incubator/kubespray.git
/opt/rh/rh-python36/root/usr/bin/pip3 install -r kubespray/requirements.txt
cp -rfp kubespray/inventory/sample kubespray/inventory/mycluster
declare -a IPS=($ip_vals)
CONFIG_FILE=kubespray/inventory/mycluster/hosts.ini /opt/rh/rh-python36/root/usr/bin/python kubespray/contrib/inventory_builder/inventory.py ${IPS[@]}
cp kubespray/inventory/mycluster/hosts.ini kubespray/inventory/mycluster/hosts.yaml
sed -i 's/# kube_basic_auth: false/kube_basic_auth: true/g' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
sed -i 's/# kube_token_auth: false/kube_token_auth: true/g' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
sed -i 's/# kube_apiserver_insecure_port:/kube_apiserver_insecure_port:/g' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
sed -i 's/kube_network_plugin: calico/kube_network_plugin: weave/g' kubespray/inventory/mycluster/group_vars/k8s-cluster/k8s-cluster.yml
sed -i "s/# kube_read_only_port:/kube_read_only_port:/g" kubespray/inventory/mycluster/group_vars/all/all.yml
sed -i "s/metrics_server_enabled: false/metrics_server_enabled: true/g" kubespray/inventory/mycluster/group_vars/k8s-cluster/addons.yml
cat kubespray/inventory/mycluster/hosts.yaml
echo "********************************* Kubernate kurulumu tamamlamak için aşağıdaki scripti çalıştırın *********************************"
echo "***********************************************************************************************************************************"
echo "************************ ansible-playbook -i kubespray/inventory/mycluster/hosts.ini kubespray/cluster.yml ************************"
echo "***********************************************************************************************************************************"
exec bash
