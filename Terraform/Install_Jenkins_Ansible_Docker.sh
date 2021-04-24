#!/usr/bin/bash
yes | sudo yum update
yes | sudo yum install wget 

# installing Jenkins git python3
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
yes | sudo yum upgrade
yes | sudo yum install jenkins java-1.8.0-openjdk-devel git python3 python3-pip

# Upgrading pip
python3 -m pip install --upgrade pip

# Installing Anible
yes | sudo pip3 install ansible

# Starting Jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins

# Instaling Dokcer
sudo amazon-linux-extras install docker

# Starting docker service
sudo service docker start

# Adding Jenkins User to Docker
sudo usermod -a -G docker jenkins

# Autostarting Docker on restarts
sudo chkconfig docker on
sudo reboot
