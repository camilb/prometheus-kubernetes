#!/bin/bash

POD=$(kubectl get pods --namespace=$NAMESPACE | grep grafana| cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=$NAMESPACE 3000:3000
