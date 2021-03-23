#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
cd $svc_config_install_path
kubectl apply -k . || true
