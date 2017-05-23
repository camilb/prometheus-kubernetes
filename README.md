# Monitoring Kubernetes  clusters on AWS using Prometheus

####Configuration

* A new namespace is created named `monitoring`
* Prometheus is deployed in a `StatefulSet` with external EBS disk attached to pod for data storage
* Nginx Ingress Controller to access the dashboards

![alt](https://www.camil.org/content/images/2016/10/prom-1.png)

#### Prerequisites

_____________________________________________________________________

######Basic
* Kubernetes cluster and `kubectl` configured.

######Alerting
* SMTP Account for email alerts.
* Token for alerts on Slack.

######AWS
* A IAM Role with EC2 ReadOnly access for EC2 instances monitoring.Only required for monitoring AWS nodes that are not part of the kubernetes cluster.

* Security Groups configured to allow port 9100/TCP for `prometheus node-exporter` and 10250/TCP for k8s nodes metrics.


#### Deployment

_____________________________________________________________________

Clone repository

    git clone github.com/camilb/prometheus-kubernetes && cd prometehus-kubernetes

Change these values in `init.sh`.

`GRAFANA_VERSION=4.3.0`

`PROMETHEUS_VERSION=v1.6.3`

`DOCKER_USER=your_dockerhub_user`

Make the necessary changes in `Configmaps` according to your setup.

**Deploy Prometheus and Grafana**

    ./init.sh

* The init script will first ask to set a username and a password for basic-auth access to Grafana, Prometheus and Alert Manager dashboards, the SMTP account password and AWS account credentials for EC2 auto-discovery.

* Configure "/etc/hosts" or create DNS records with the hosts and IP from the Ingress Controller.

   You can always get the Ingress Controller configuration by running:

        kubectl get ing -n monitoring

* The script will ask to perform a cleanup, removing the sensitive data from k8s config files. The changes can be kept locally and erased later using `cleanup.sh` script.



You can now access the Grafana and Prometheus dashboards
