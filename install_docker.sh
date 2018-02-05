#!/bin/sh

sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

/usr/bin/curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install -y docker-ce=17.03.2~ce-0~ubuntu-xenial

sudo usermod -aG docker ubuntu
