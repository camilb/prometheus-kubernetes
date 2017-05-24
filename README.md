# Monitoring Kubernetes  clusters on AWS using Prometheus

## Configuration

* A new namespace is created named `monitoring`
* Prometheus is deployed in a `StatefulSet` with external EBS disk attached to pod for data storage
* Nginx Ingress Controller to access the dashboards

![alt](https://www.camil.org/content/images/2016/10/prom-1.png)

## Prerequisites

* Kubernetes cluster and `kubectl` configured.
* SMTP Account for email alerts.
* Token for alerts on Slack.
* A IAM Role with EC2 ReadOnly access for EC2 instances monitoring. Only required for monitoring AWS nodes that are not part of the kubernetes cluster.
* Security Groups configured to allow port 9100/TCP for `prometheus node-exporter` and 10250/TCP for k8s nodes metrics.


## Pre-Deployment

Clone repository

    git clone github.com/camilb/prometheus-kubernetes && cd prometehus-kubernetes

Make any desired configration changes in `configmaps` according to your setup.
* ./k8s/prometheus/01-prometheus.configmap.yaml
* ./k8s/prometheus/03-alertmanager.configmap.yaml


## Deploy Prometheus with Grafana

    ./init.sh

* The init script will ask some basic questions and attempt to autodiscover information about your system. 

* Configure "/etc/hosts" or create DNS records with the hosts and IP from the Ingress Controller.

   You can always get the Ingress Controller configuration by running:

        kubectl get ing -n monitoring

* The script will ask to perform a cleanup, removing the sensitive data from k8s config files. The changes can be kept locally and erased later using `cleanup.sh` script.



You can now access the Grafana and Prometheus dashboards
