# Monitoring Kubernetes  clusters on AWS, GCP and Azure using Prometheus Operator by CoreOS


![alt](https://www.camil.org/content/images/2017/cluster.png)

**Note:** the work on this repository is now based on CoreOS's [kube-prometheus](https://github.com/coreos/prometheus-operator/tree/master/contrib/kube-prometheus) and it will be the default option for Kubernetes 1.7.X and up. For 1.5.X and 1.6.X you can deploy a simpler solution, located in `./basic` directory.
The purpose of this project is to provide a simple and interactive method to deploy and configure Prometheus on Kubernetes, especially for the users that are not using Helm.

## Features
* Prometheus Operator with support for Prometheus v2.X.X
* highly available Prometheus and Alertmaneger
* InCluster deployment using `StatefulSets` for persistent storage
* auto-discovery for services and pods
* automatic RBAC configuration
* preconfigured alerts
* preconfigured Grafana dashboards
* easy to setup; usually less than a minute to deploy a complete monitoring solution for Kubernetes
* support for Kubernetes  v1.7.x and up running in  **AWS**, **GCP** and **Azure**
* tested on clusters deployed using [kube-aws](https://github.com/kubernetes-incubator/kube-aws), [kops](https://github.com/kubernetes/kops), [GKE](https://cloud.google.com/container-engine/) and [Azure](https://azure.microsoft.com)
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
* Token for Slack alerts

## Pre-Deployment

Clone the repository and checkout the latest release: `curl -L https://git.io/getPrometheusKubernetes | sh -`


## Custom settings

All the components versions can be configured using the interactive deployment script. Same for the SMTP account or the Slack token.

Some other settings that can be changed before deployment:
  * **Prometheus replicas:** default **2** ==> `manifests/prometheus/prometheus-k8s.yaml`
  * **persistent volume size:** default **40Gi** ==> `manifests/prometheus/prometheus-k8s.yaml`
  * **allocated memory for Prometheus pods:** default **2Gi** ==> `manifests/prometheus/prometheus-k8s.yaml`
  * **Alertmanager replicas:** default **3** ==> `manifests/alertmanager/alertmanager.yaml`
  * **Alertmanager configuration:** ==> `assets/alertmanager/alertmanager.yaml`
  * **custom Grafana dashboards:** add yours in `assets/grafana/` with names ending in `-dashboard.json`
  * **custom alert rules:**  ==> `assets/prometheus/rules/`

**Note:** please commit your changes before deployment if you wish to keep them. The `deploy` script will remove the changes on most of the files.

## Deploy

    ./deploy

Now you can access the dashboards locally using `kubectl port-forward`command, or expose the services using a ingress or a LoadBalancer. Please check the `./tools` directory to quickly configure a ingress or proxy the services to localhost.

To remove everything, just execute the `./teardown` script.


## Updating configurations

  * **update alert rules:** add or change the rules in `assets/prometheus/rules/` and execute `scripts/generate-rules-configmap.sh`. Then apply the changes using `kubectl apply -f manifests/prometheus/prometheus-k8s-rules.yaml -n monitoring`
  * **update grafana dashboards:** add or change the existing dashboards in `assets/grafana/` and execute `scripts/generate-dashboards-configmap.sh`. Then apply the changes using `kubectl apply -f manifests/grafana/grafana-dashboards.cm.yaml`.

**Note:** all the Grafana dashboards should have names ending in `-dashboard.json`.

## Custom Prometheus configuration

  The official documentation for Prometheus Operator custom configuration can be found here: [custom-configuration.md](https://github.com/coreos/prometheus-operator/blob/master/Documentation/custom-configuration.md)
  If you wish, you can update the Prometheus configuration using the `./tools/custom-configuration/update_config` script.
