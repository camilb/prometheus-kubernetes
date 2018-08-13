#!/bin/bash

POD=$(kubectl get pods --namespace=$NAMESPACE | grep prometheus-k8s-0| cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=$NAMESPACE 9090:9090
