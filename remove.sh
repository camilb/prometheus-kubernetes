#!/bin/bash

kubectl delete -f ./k8s/grafana
kubectl delete -R -f ./k8s/prometheus
kubectl delete -f ./k8s/kube-state-metrics
kubectl delete -f ./k8s/rbac/prometheus-rbac.yaml
kubectl delete -f ./k8s/rbac/kube-state-metrics-rbac.yaml
kubectl delete ns monitoring
