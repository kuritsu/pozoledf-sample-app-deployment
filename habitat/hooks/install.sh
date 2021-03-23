#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
cd "{{pkg.svc_config_install_path}}"
kubectl apply -k . || true
