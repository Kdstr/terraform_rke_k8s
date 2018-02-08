#!/bin/sh

cd /tmp

curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl

mv /tmp/kubectl /usr/local/bin/kubectl

chmod +x /usr/local/bin/kubectl
