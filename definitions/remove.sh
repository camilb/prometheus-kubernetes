#!/bin/bash

kubectl delete -f ./k8s/grafana
kubectl delete -f ./k8s/ingress
kubectl delete -f ./k8s/prometheus
kubectl delete -f ./k8s/kube-state-metrics
kubectl delete secret dhparam -n monitoring
