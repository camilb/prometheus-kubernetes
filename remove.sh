#!/bin/bash

kubectl delete -f ./k8s/grafana
kubectl delete -R -f ./k8s/prometheus
kubectl delete -f ./k8s/kube-state-metrics
kubectl delete -f ./k8s/rbac/01-prometheus-rbac-config.yaml
kubectl delete -f ./k8s/rbac/03-kube-state-metrics-rbac-config.yaml

#Remove the Nginx Ingress Controller
echo
echo -e "${BLUE}Do you want to remove the Nginx Ingress Controller?"
tput sgr0
read -p "Y/N [N]: " remove_ingress

if [[ $remove_ingress =~ ^([yY][eE][sS]|[yY])$ ]]; then
  kubectl delete -f ./k8s/ingress
  kubectl delete -f ./k8s/rbac/02-nginx-ingress-rbac-config.yaml
  kubectl delete ns nginx-ingress
fi

kubectl delete ns monitoring
