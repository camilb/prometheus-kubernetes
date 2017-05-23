#!/bin/bash

kubectl delete -f ./k8s/grafana
kubectl delete -f ./k8s/ingress
kubectl delete -R -f ./k8s/prometheus
kubectl delete -f ./k8s/kube-state-metrics
kubectl delete -f ./k8s/rbac
kubectl delete ns monitoring
