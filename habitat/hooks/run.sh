#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
while [ true ]; do
  kubectl logs -f -lapp=app --all-containers=true -n pozoledf
  sleep 5s
done
