---
network:
  plugin: flannel
  options:
    flannel_image: quay.io/coreos/flannel:v0.9.1
    flannel_cni_image: quay.io/coreos/flannel-cni:v0.2.0

auth:
  strategy: x509
  options:
    foo: bar

 
services:
  etcd:
    image: quay.io/coreos/etcd:latest
  kube-api:
    image: rancher/k8s:v1.8.3-rancher2
  kube-controller:
    image: rancher/k8s:v1.8.3-rancher2
  scheduler:
    image: rancher/k8s:v1.8.3-rancher2
  kubelet:
    image: rancher/k8s:v1.8.3-rancher2
  kubeproxy:
    image: rancher/k8s:v1.8.3-rancher2


nodes:
