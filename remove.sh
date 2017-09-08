#!/bin/bash

kubectl delete -f ./k8s/grafana
kubectl delete -R -f ./k8s/prometheus
kubectl delete -f ./k8s/kube-state-metrics
kubectl delete -f ./k8s/rbac/01-prometheus-rbac-config.yaml
kubectl delete -f ./k8s/rbac/03-kube-state-metrics-rbac-config.yaml
kubectl delete ing prometheus -n monitoring
kubectl delete ns monitoring
