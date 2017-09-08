#!/bin/bash
#AWS_DEFAULT_AVAILABILITY_ZONE=us-east-1c
GRAFANA_DEFAULT_VERSION=4.5.0-beta1
PROMETHEUS_DEFAULT_VERSION=v2.0.0-beta.2
ALERT_MANAGER_DEFAULT_VERSION=v0.8.0
NODE_EXPORTER_DEFAULT_VERSION=v0.14.0
KUBE_STATE_METRICS_DEFAULT_VERSION=v1.0.1
DOCKER_USER_DEFAULT=$(docker info|grep Username:|awk '{print $2}')
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

#Ask for AWS availability zone
#read -p "Enter your desired availability zone to deploy Prometheus StatefulSet [$AWS_DEFAULT_AVAILABILITY_ZONE]: " AWS_AVAILABILITY_ZONE
#AWS_AVAILABILITY_ZONE=${AWS_AVAILABILITY_ZONE:-$AWS_DEFAULT_AVAILABILITY_ZONE}

#Ask for grafana version or apply default
echo
read -p "Enter Grafana version [$GRAFANA_DEFAULT_VERSION]: " GRAFANA_VERSION
GRAFANA_VERSION=${GRAFANA_VERSION:-$GRAFANA_DEFAULT_VERSION}

#Ask for prometheus version or apply default
read -p "Enter Prometheus version [$PROMETHEUS_DEFAULT_VERSION]: " PROMETHEUS_VERSION
PROMETHEUS_VERSION=${PROMETHEUS_VERSION:-$PROMETHEUS_DEFAULT_VERSION}

#Ask for alertmanager version or apply default
read -p "Enter Alert Manager version [$ALERT_MANAGER_DEFAULT_VERSION]: " ALERT_MANAGER_VERSION
ALERT_MANAGER_VERSION=${ALERT_MANAGER_VERSION:-$ALERT_MANAGER_DEFAULT_VERSION}


#Ask for node exporter version or apply default
read -p "Enter Node Exporter version [$NODE_EXPORTER_DEFAULT_VERSION]: " NODE_EXPORTER_VERSION
NODE_EXPORTER_VERSION=${NODE_EXPORTER_VERSION:-$NODE_EXPORTER_DEFAULT_VERSION}

#Ask for kube-state-metrics version or apply default
read -p "Enter Kube Stae Metrics version [$KUBE_STATE_METRICS_DEFAULT_VERSION]: " KUBE_STATE_METRICS_VERSION
KUBE_STATE_METRICS_VERSION=${KUBE_STATE_METRICS_VERSION:-$KUBE_STATE_METRICS_DEFAULT_VERSION}

#Ask for dockerhub user or apply default of the current logged-in username
read -p "Enter Dockerhub username [$DOCKER_USER_DEFAULT]: " DOCKER_USER
DOCKER_USER=${DOCKER_USER:-$DOCKER_USER_DEFAULT}

#Replace Dockerhub username in grafana deployment.
sed -i -e 's/DOCKER_USER/'"$DOCKER_USER"'/g' k8s/grafana/grafana.svc.deployment.yaml

#Do you want to set up an SMTP relay?
echo
echo -e "${BLUE}Do you want to set up an SMTP relay?"
tput sgr0
read -p "Y/N [N]: " use_smtp

#if so, fill out this form...
if [[ $use_smtp =~ ^([yY][eE][sS]|[yY])$ ]]; then
  #smtp smarthost
  read -p "SMTP smarthost: " smtp_smarthost
  #smtp from address
  read -p "SMTP from (user@domain.com): " smtp_from
  #smtp to address
  read -p "Email address to send alerts to (user@domain.com): " alert_email_address
  #smtp username
  read -p "SMTP auth username: " smtp_user
  #smtp password
  prompt="SMTP auth password: "
  while IFS= read -p "$prompt" -r -s -n 1 char
  do
      if [[ $char == $'\0' ]]
      then
          break
      fi
      prompt='*'
      smtp_password+="$char"
  done

  #update configmap with SMTP relay info
  sed -i -e 's/your_smtp_smarthost/'"$smtp_smarthost"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
  sed -i -e 's/your_smtp_from/'"$smtp_from"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
  sed -i -e 's/your_smtp_user/'"$smtp_user"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
  sed -i -e 's,your_smtp_pass,'"$smtp_password"',g' k8s/prometheus/03-alertmanager.configmap.yaml
  sed -i -e 's/your_alert_email_address/'"$alert_email_address"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
fi

#Do you want to set up slack?
echo
echo -e "${BLUE}Do you want to set up slack alerts?"
tput sgr0
read -p "Y/N [N]: " use_slack

#if so, fill out this form...
if [[ $use_slack =~ ^([yY][eE][sS]|[yY])$ ]]; then

  read -p "Slack api token: " slack_api_token
  read -p "Slack channel: " slack_channel

  #again, our sed is funky due to slashes appearing in slack api tokens
  sed -i -e 's,your_slack_api_token,'"$slack_api_token"',g' k8s/prometheus/03-alertmanager.configmap.yaml
  sed -i -e 's/your_slack_channel/'"$slack_channel"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
fi


#Do you want to monitor EC2 instances in your AWS account?
echo
echo -e "${BLUE}Do you want to monitor EC2 instances in your AWS account?"
tput sgr0
read -p "Y/N [N]: " monitor_aws

#if so, fill out this form...
if [[ $monitor_aws =~ ^([yY][eE][sS]|[yY])$ ]]; then

  #try to figure out AWS credentials for EC2 monitoring, if not...ask.
  echo
  echo -e "${BLUE}Detecting AWS access keys."
  tput sgr0
  if [ ! -z $AWS_ACCESS_KEY_ID ] && [ ! -z $AWS_SECRET_ACCESS_KEY ]; then
    aws_access_key=$AWS_ACCESS_KEY_ID
    aws_secret_key=$AWS_SECRET_ACCESS_KEY
    echo -e "${ORANGE}AWS_ACCESS_KEY_ID found, using $aws_access_key."
    tput sgr0
  elif [ ! -z $AWS_ACCESS_KEY ] && [ ! -z $AWS_SECRET_KEY ]; then
    aws_access_key=$AWS_ACCESS_KEY
    aws_secret_key=$AWS_SECRET_KEY
    echo -e "${ORANGE}AWS_ACCESS_KEY found, using $aws_access_key."
    tput sgr0
  else
    echo -e "${RED}Unable to determine AWS credetials from environment variables."
    tput sgr0
    #aws access key
    read -p "AWS Access Key ID: " aws_access_key
    #aws secret access key
    read -p "AWS Secret Access Key: " aws_secret_key
  fi

  #sed in the AWS credentials. this looks odd because aws secret access keys can have '/' as a valid character
  #so we use ',' as a delimiter for sed, since that won't appear in the secret key
  sed -i -e 's/aws_access_key/'"$aws_access_key"'/g' k8s/prometheus/01-prometheus.configmap.yaml
  sed -i -e 's,aws_secret_key,'"$aws_secret_key"',g' k8s/prometheus/01-prometheus.configmap.yaml

else
  rm grafana/grafana-dashboards/ec2-instances.json
fi

echo
echo -e "${BLUE}Creating ${ORANGE}'monitoring' ${BLUE}namespace."
tput sgr0
#create a separate namespace for monitoring
kubectl create namespace monitoring

echo
echo -e "${BLUE}Is the RBAC plugin enabled?"
tput sgr0
read -p "[y/N]: " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    kubectl create -f ./k8s/rbac/01-prometheus-rbac-config.yaml
    kubectl create -f ./k8s/rbac/03-kube-state-metrics-rbac-config.yaml
    sed -i -e 's/default/'prometheus'/g' k8s/prometheus/02-prometheus.svc.statefulset.yaml
    sed -i -e 's/default/'kube-state-metrics'/g' k8s/kube-state-metrics/deployment.yaml
else
    echo -e "${GREEN}Skipping RBAC configuration"
fi
tput sgr0

#aws availability zone
#sed -i -e 's/AWS_AVAILABILITY_ZONE/'"$AWS_AVAILABILITY_ZONE"'/g' k8s/prometheus/02-prometheus.svc.statefulset.yaml

#set prometheus version
sed -i -e 's/PROMETHEUS_VERSION/'"$PROMETHEUS_VERSION"'/g' k8s/prometheus/02-prometheus.svc.statefulset.yaml

#set grafana version
sed -i -e 's/GRAFANA_VERSION/'"$GRAFANA_VERSION"'/g' grafana/Dockerfile
sed -i -e 's/GRAFANA_VERSION/'"$GRAFANA_VERSION"'/g' k8s/grafana/grafana.svc.deployment.yaml

#set alertmanager version
sed -i -e 's/ALERT_MANAGER_VERSION/'"$ALERT_MANAGER_VERSION"'/g' k8s/prometheus/04-alertmanager.svc.deployment.yaml

#set node-exporter version
sed -i -e 's/NODE_EXPORTER_VERSION/'"$NODE_EXPORTER_VERSION"'/g' k8s/prometheus/05-node-exporter.svc.daemonset.yaml

#set node-exporter version
sed -i -e 's/KUBE_STATE_METRICS_VERSION/'"$KUBE_STATE_METRICS_VERSION"'/g' k8s/kube-state-metrics/deployment.yaml

#remove  "sed" generated files
rm k8s/prometheus/*.yaml-e && rm k8s/grafana/*.yaml-e && rm grafana/*-e kube-state-metrics/*.yaml-e 2> /dev/null

#build grafana image, push to dockerhub
echo
echo -e "${BLUE}Building Grafana Docker image and pushing to dockerhub"
tput sgr0
docker build -t $DOCKER_USER/grafana:$GRAFANA_VERSION ./grafana --no-cache
docker push $DOCKER_USER/grafana:$GRAFANA_VERSION
#upon failure, run docker login
if [ $? -eq 1 ];then
  echo -e "${RED}docker push failed! perhaps you need to login \"${DOCKER_USER}\" to dockerhub?"
  tput sgr0
  docker login -u $DOCKER_USER
  #try again
  docker push $DOCKER_USER/grafana:$GRAFANA_VERSION
  if [ $? -eq 1 ];then
    echo -e "${RED}docker push failed a second time! exiting."
    ./cleanup.sh
    exit 1
  fi
fi


#deploy grafana
echo
echo -e "${ORANGE}Deploying Grafana"
tput sgr0
kubectl create -f k8s/grafana

#deploy prometheus
echo
echo -e "${ORANGE}Deploying Prometheus"
tput sgr0
kubectl create -R -f ./k8s/prometheus

#deploy kube-state-metrics
echo
echo -e "${ORANGE}Deploying Kube State Metrics exporter"
tput sgr0
kubectl create -f ./k8s/kube-state-metrics
echo

echo -e "${BLUE}Do you want to set up Nginx Ingress Controller?"
tput sgr0

read -p "Y/N [N]: " deploy_nginx_ingress
echo

if [[ $deploy_nginx_ingress =~ ^([yY][eE][sS]|[yY])$ ]]; then

  #create a separate namespace for ingress controller
  echo -e "${BLUE}Creating ${ORANGE}'nginx-ingress' ${BLUE}namespace."
  kubectl create namespace nginx-ingress

  echo
  echo -e "${BLUE}Is the RBAC plugin enabled?"
  tput sgr0
  read -p "[y/N]: " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
  then
      kubectl create -f ./k8s/rbac/02-nginx-ingress-rbac-config.yaml
  else
      echo -e "${GREEN}Skipping RBAC configuration"
  fi
  tput sgr0

  echo
  echo -e "${GREEN}Type your domain name."
  tput sgr0

  read -p "domain: " domain_name

  sed -i -e 's/domain_name/'"$domain_name"'/g' k8s/ingress/03-prometheus.ing.yaml

  #Set username and password for basic-auth
  echo
  echo -e "${BLUE}Please set the username and password for basic-auth to prometheus and alertmanager:"
  tput sgr0
  read -p "Set username [monitor]: " username
  htpasswd -c auth ${username:-'monitor'}

  #base64 encode the basic-auth and set the secret
  BASIC_AUTH=$(cat ./auth | base64)
  sed -i -e 's/htpasswd/'"$BASIC_AUTH"'/g' k8s/ingress/01-basic-auth.secret.yaml


  #deploy ingress controller
  echo
  echo -e "${BLUE}Deploying  K8S Ingress Controller"
  tput sgr0
  kubectl create -f ./k8s/ingress

  #wait for the ingress to become available.
  echo
  echo -e "${BLUE}Waiting 10 seconds for the Ingress Controller to become available."
  tput sgr0
  sleep 10

  #get ingress IP and hosts, display for user
  PROM_INGRESS=$(kubectl get ing --namespace=monitoring)
  echo
  echo 'Configure "/etc/hosts" or create DNS records for these hosts:' && printf "${RED}$PROM_INGRESS"
  echo
else
  echo -e "${BLUE}If you already have a nginx Ingress controller, would you like to configure a ingress to expose the services?"
  tput sgr0

  read -p "Y/N [N]: " config_ingress
  echo

  if [[ $config_ingress =~ ^([yY][eE][sS]|[yY])$ ]]; then

    echo
    echo -e "${GREEN}Type your domain name."
    tput sgr0

    read -p "domain: " domain_name

    sed -i -e 's/domain_name/'"$domain_name"'/g' k8s/ingress/03-prometheus.ing.yaml

    #Set username and password for basic-auth
    echo
    echo -e "${BLUE}Please set the username and password for basic-auth to prometheus and alertmanager:"
    tput sgr0
    read -p "Set username [monitor]: " username
    htpasswd -c auth ${username:-'monitor'}

    #base64 encode the basic-auth and set the secret
    BASIC_AUTH=$(cat ./auth | base64)
    sed -i -e 's/htpasswd/'"$BASIC_AUTH"'/g' k8s/ingress/01-basic-auth.secret.yaml


    #deploy ingress controller
    echo
    echo -e "${BLUE}Deploying  K8S Ingress Controller"
    tput sgr0
    kubectl create -f ./k8s/ingress/01-basic-auth.secret.yaml
    kubectl create -f ./k8s/ingress/03-prometheus.ing.yaml

    #wait for the ingress to become available.
    echo
    echo -e "${BLUE}Waiting 10 seconds for the Ingress Controller to become available."
    tput sgr0
    sleep 10

    #get ingress IP and hosts, display for user
    PROM_INGRESS=$(kubectl get ing --namespace=monitoring)
    echo
    echo 'Configure "/etc/hosts" or create DNS records for these hosts:' && printf "${RED}$PROM_INGRESS"
    echo

  fi
  #remove  "sed" generated files
  rm k8s/ingress/*.yaml-e
  rm k8s/kube-state-metrics/*.yaml-e
fi


echo
#cleanup
echo -e "${GREEN}Cleaning modified files"
tput sgr0

read -r -p "Remove the changes made? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    ./cleanup.sh
else
    echo -e "${RED}No cleanup was perfromed. Please consider removing the sensitive data in files before pushing changes to ${ORANGE}GitHUB"
fi
echo

GRAFANA_POD=$(kubectl get pods --namespace=monitoring | grep grafana | cut -d ' ' -f 1)

#import prometheus datasource in grafana using Grafana API.
#proxy grafana to localhost to import datasource using Grafana API.

kubectl port-forward $GRAFANA_POD --namespace=monitoring 3000:3000 > /dev/null 2>&1 &

echo -e "${GREEN}Importing Prometheus datasource."
tput sgr0
sleep 5
curl 'http://admin:admin@127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"prometheus.monitoring.svc.cluster.local","type":"prometheus","url":"http://prometheus.monitoring.svc.cluster.local:9090","access":"proxy","isDefault":true}' 2> /dev/null 2>&1

#check datasources
echo
echo -e "${GREEN}Checking datasource"
tput sgr0
curl 'http://admin:admin@127.0.0.1:3000/api/datasources' 2> /dev/null 2>&1

# kill the backgrounded proxy process
kill $!

# set up proxy for the user
echo
echo -e "${GREEN}Complete"
