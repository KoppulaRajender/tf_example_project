#!/usr/bin/env bash
# This script install Jenkins in your Ubuntu System
#
# This script must be run as root:

#if [[ EUID -ne 0 ]]; then
#	echo "This script must be run as root" 1>&2
#	exit 1
#fi

# Update apt
sudo apt update  --assume-yes

# Install the necessary packages to prepare the environment
sudo apt-get install autoconf bison build-essential libffi-dev libssl-dev  --assume-yes
sudo apt-get install libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev curl git vim  software-properties-common  --assume-yes

# Install Java Run
sudo apt install default-jre  --assume-yes
sudo apt install default-jdk  --assume-yes


# Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update  --assume-yes
sudo apt install jenkins  --assume-yes
sudo systemctl start jenkins
sudo systemctl status jenkins


# Ansible
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install ansible  --assume-yes

