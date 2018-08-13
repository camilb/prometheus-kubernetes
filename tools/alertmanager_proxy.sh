#!/bin/bash

#Namespace
NAMESPACE=$(kubectl get sts --all-namespaces | grep prometheus-k8s | cut -d " " -f1)

POD=$(kubectl get pods --namespace=$NAMESPACE | grep alertmanager-main-0| cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=$NAMESPACE 9093:9093
