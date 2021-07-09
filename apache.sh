#!/bin/sh
sudo pip3 install ansible
export ANSIBLE_HOST_KEY_CHECKING=False
sudo mkdir /etc/ansible/
sudo touch /etc/ansible/hosts
ip addr show eth0 | grep 'inet ' | awk '{print $2}'           | cut -f1 -d'/' >> /tmp/hosts
sudo cp /tmp/hosts /etc/ansible/hosts
ansible-playbook -b -v -u ec2-user --private-key instance_login.pem apache.yml
