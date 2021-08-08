#!/bin/bash
oc login cluster-endpoint:6443 -u kubeadmin -p cluster-password
oc project loki
