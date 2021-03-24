#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
cd "{{pkg.svc_config_install_path}}"
if [ -f "/home/hab/docker-private.sh" ]; then
  bash /home/hab/docker-private.sh
fi
kubectl apply -k . || true
