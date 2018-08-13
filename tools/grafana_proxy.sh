#!/bin/bash

#Namespace
NAMESPACE=$(kubectl get sts --all-namespaces | grep prometheus-k8s | cut -d " " -f1)

POD=$(kubectl get pods --namespace=$NAMESPACE | grep grafana| cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=$NAMESPACE 3000:3000
