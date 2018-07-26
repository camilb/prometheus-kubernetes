#!/bin/bash

POD=$(kubectl get pods --namespace=monitoring | grep grafana | grep -v es | cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=monitoring 3000:3000
