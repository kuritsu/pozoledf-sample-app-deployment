#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig

cd "{{pkg.svc_config_install_path}}"
if [ -f "/home/hab/docker-private.sh" ]; then
  # This script needs to set the docker credentials in /home/hab/.docker/config.json
  bash /home/hab/docker-private.sh
fi

kubectl apply -k . || true

if [ -f "/home/hab/docker-private.sh" ]; then
  kubectl create secret generic regcred \
      -n pozoledf \
      --from-file=.dockerconfigjson=/home/hab/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson || true
fi
