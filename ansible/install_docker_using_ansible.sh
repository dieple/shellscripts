#!/bin/bash

# make sure latest version of ansible installed before running this script
# uncomment if not already installed

#sudo apt-get update
#sudo apt-get install software-properties-common
#sudo apt-add-repository ppa:ansible/ansible
#sudo apt-get update
#sudo apt-get install ansible


sudo ansible-galaxy install angstwad.docker_ubuntu

sudo cat <<-EOH >> /etc/ansible/hosts
[local]
  localhost
EOH

sudo cat <<-EOH > /tmp/docker.yml
---
  - hosts: local
    connection: local
    roles:
      - angstwad.docker_ubuntu
EOH

sudo ansible-playbook /tmp/docker.yml
