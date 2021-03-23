#!/bin/bash

export KUBECONFIG=/home/hab/kubeconfig
kubectl apply -k . || true
