# Monitoring Kubernetes  clusters on AWS using Prometheus


![alt](https://www.camil.org/content/images/2017/cluster.png)

One minute deployment
[![asciicast](https://asciinema.org/a/QdIFKxowJ9XOSpS9QYuGI23J5.png)](https://asciinema.org/a/QdIFKxowJ9XOSpS9QYuGI23J5)

## Configuration

* A new namespace is created named `monitoring`
* Prometheus is deployed using a `StatefulSet` with external EBS disk attached to the pod for data storage

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

Make any desired configuration changes in `configmaps` according to your setup.
* ./k8s/prometheus/prometheus.cm.yaml
* ./k8s/prometheus/alertmanager.cm.yaml


## Deploy Prometheus, Alertmaneger, Node Exporter, Grafana and Kube State Metrics

    ./init.sh

* The init script will ask some basic questions and attempt to auto-discover information about your system.


Now you can access the dashboards locally using `kubectl port-forward`command, creating a ingress or a LoadBalancer. Please check the `./tools` directory if to quickly configure a ingress or proxy the services to localhost.
