#!/bin/bash

POD=$(kubectl get pods --namespace=monitoring | grep prometheus| cut -d ' ' -f 1)
kubectl port-forward $POD --namespace=monitoring 9090:9090
