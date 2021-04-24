#!/usr/bin/bash
yes | sudo yum update
yes | sudo yum install wget 
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yes | sudo yum upgrade
yes | sudo yum install jenkins java-1.8.0-openjdk-devel git python3 python3-pip
sudo -H pip3 install --upgrade pip
yes | sudo pip install ansible
sudo systemctl daemon-reload
sudo systemctl start jenkins
