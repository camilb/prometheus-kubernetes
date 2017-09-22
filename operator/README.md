# Monitoring Kubernetes  clusters on AWS using Prometheus Operator by CoreOS


![alt](https://www.camil.org/content/images/2017/cluster.png)

Note: the work on this directory is based on CoreOs's [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus).
The purpose of this project is to provide a simple and interactive method to deploy Prometheus Operator.

## Features
* Prometheus Operator with support for Prometheus v2.X.X
* highly available Prometheus and Alermaneger
* InCluster deployment using `StatefulSets` for persistent storage
* auto-discovery for services and pods
* automatic RBAC configuration
* preconfigured alerts
* preconfigured Grafana dashboards
* easy to setup; usually less than a minute to deploy a basic monitoring solution for Kubernetes
* support for Kubernetes v1.7.x and up

## One minute deployment

[![asciicast](https://asciinema.org/a/139033.png)](https://asciinema.org/a/139033)

## Prerequisites

* Kubernetes cluster and `kubectl` configured
* Security Groups configured to allow the fallowing ports:
     * 9100/TCP  -                node-exporter
     * 10250/TCP -                kubernetes nodes metrics,
     * 10251/TCP -                kube-scheduler
     * 10252/TCP -                kube-controller-manager
     * 10054/TCP and 10055/TCP -  kube-dns

#### Optional
* SMTP Account for email alerts
* Token for alerts on Slack

## Pre-Deployment

Clone repository

    git clone github.com/camilb/prometheus-kubernetes && cd prometehus-kubernetes

Make any desired configuration changes in `./assets` according to your setup.
You can also change the number of replicas for prometheus (default: 2) and alertmanager (default: 3)


## Deploy

    ./deploy

* The deploy script will ask some basic questions and attempt to auto-discover information about your system.


Now you can access the dashboards locally using `kubectl port-forward`command, creating a ingress or a LoadBalancer. Please check the `./tools` directory to quickly configure a ingress or proxy the services to localhost.

To remove everything, just execute the `./teardown` script.
