#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
cd $pkg_svc_config_path
kubectl apply -k . || true
