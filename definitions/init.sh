#!/bin/bash

GRAFANA_DEFAULT_VERSION=4.2.0
PROMETHEUS_DEFAULT_VERSION=v1.6.3
DOCKER_USER_DEFAULT=$(docker info|grep Username:|awk '{print $2}')
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

echo -e "${BLUE}Creating 'monitoring' namespace."
tput sgr0

#create a separate namespace for monitoring
kubectl create namespace monitoring

#Ask for grafana version or apply default
echo
read -p "Enter Grafana version [$GRAFANA_DEFAULT_VERSION]: " GRAFANA_VERSION
GRAFANA_VERSION=${GRAFANA_VERSION:-$GRAFANA_DEFAULT_VERSION}

#Ask for prometheus version or apply default
echo
read -p "Enter Prometheus version [$PROMETHEUS_DEFAULT_VERSION]: " PROMETHEUS_VERSION
PROMETHEUS_VERSION=${PROMETHEUS_VERSION:-$PROMETHEUS_DEFAULT_VERSION}

#Ask for dockerhub user or apply default of the current logged-in username
echo
read -p "Enter Dockerhub username [$DOCKER_USER_DEFAULT]: " DOCKER_USER
DOCKER_USER=${DOCKER_USER:-$DOCKER_USER_DEFAULT}

#Set username and password for basic-auth
echo
echo -e "${BLUE}Please set the username and password for basic-auth and [ENTER]:"
tput sgr0

prompt="Set username:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt=$char
    username+="$char"
done
echo

htpasswd -c auth $username

#base64 encode the basic-auth and set the secret
BASIC_AUTH=$(cat ./auth | base64)

sed -i -e 's/htpasswd/'"$BASIC_AUTH"'/g' k8s/ingress/01-basic-auth.secret.yaml

echo

#Replace Dockerhub username in grafana deployment.

sed -i -e 's/DOCKER_USER/'"$DOCKER_USER"'/g' k8s/grafana/grafana.svc.deployment.yaml

#password for SMTP account in alertmanager ConfigMap.
echo -e "${BLUE}Insert the password for SMTP account and press [ENTER]:"
tput sgr0

prompt="SMTP Password:"
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt='*'
    smtp_password+="$char"
done
echo

sed -i -e 's/smtp_pass/'"$smtp_password"'/g' k8s/prometheus/03-alertmanager.configmap.yaml
echo -e "${BLUE}SMTP password set."
tput sgr0
echo

#try to figure out AWS credentials for EC2 monitoring, if not...ask.
echo -e "${BLUE}Detecting AWS access keys."
tput sgr0
echo
if [ ! -z $AWS_ACCESS_KEY_ID ] && [ ! -z $AWS_SECRET_ACCESS_KEY ]; then
  aws_access_key=$AWS_ACCESS_KEY_ID
  aws_access_password=$AWS_SECRET_ACCESS_KEY
  echo -e "${ORANGE}AWS_ACCESS_KEY_ID found, using $aws_access_key."
  tput sgr0
  echo
elif [ ! -z $AWS_ACCESS_KEY ] && [ ! -z $AWS_SECRET_KEY ]; then
  aws_access_key=$AWS_ACCESS_KEY
  aws_access_password=$AWS_SECRET_KEY
  echo -e "${ORANGE}AWS_ACCESS_KEY found, using $aws_access_key."
  tput sgr0
  echo
else
  echo -e "${RED}Unable to determine AWS credetials from environment variables."
  echo -e "${ORANGE}Insert your AWS Access Key ID and press [ENTER]:"
  tput sgr0

  #aws access key
  prompt="AWS Access Key ID:"
  tput sgr0
  while IFS= read -p "$prompt" -r -s -n 1 char
  do
      if [[ $char == $'\0' ]]
      then
          break
      fi
      prompt='*'
      aws_access_key+="$char"
  done
  echo

  #aws secret access key
  echo -e "${ORANGE}Insert your AWS Secret Access Key and press [ENTER]:"
  tput sgr0

  prompt="AWS Secret Access Key:"
  tput sgr0
  while IFS= read -p "$prompt" -r -s -n 1 char
  do
      if [[ $char == $'\0' ]]
      then
          break
      fi
      prompt='*'
      aws_access_password+="$char"
  done
  echo
fi

#sed in the AWS credentials. this looks odd because aws secret access keys can have '/' as a valid character
#so we use ',' as a delimiter for sed, since that won't appear in the secret key
sed -i -e 's/aws_access_key/'"$aws_access_key"'/g' k8s/prometheus/01-prometheus.configmap.yaml
sed -i -e 's,aws_access_password,'"$aws_access_password"',g' k8s/prometheus/01-prometheus.configmap.yaml

#slack channel
echo -e "${PURPLE}Insert your slack channel name where you wish to receive alerts and press [ENTER]:"
tput sgr0

prompt="Slack channel:"
tput sgr0
while IFS= read -p "$prompt" -r -s -n 1 char
do
    if [[ $char == $'\0' ]]
    then
        break
    fi
    prompt=$char
    slack_channel+="$char"
done
echo
sed -i -e 's/slack_channel/'"$slack_channel"'/g' k8s/prometheus/03-alertmanager.configmap.yaml


#remove  "sed" generated files
rm k8s/prometheus/*.yaml-e && rm k8s/ingress/*.yaml-e && rm k8s/grafana/*.yaml-e

echo

#nginx load balancer display errors if dhparam is not set
echo -e "${RED}Generate DH parameters for nginx."
openssl dhparam -out dhparam.pem 1024
tput sgr0

echo -e "${BLUE}Create dhparam secret."
tput sgr0
kubectl create secret generic dhparam --from-file=dhparam.pem -n monitoring

echo

#build grafana image
echo -e "${BLUE}Building Grafana Docker image"
tput sgr0
docker build -t $DOCKER_USER/grafana:$GRAFANA_VERSION ./grafana --no-cache

echo

echo -e "${BLUE}Pushing grafana docker image to DockerHub"
tput sgr0
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

echo

#deploy grafana
echo -e "${RED}Deploying Grafana"
tput sgr0
kubectl create -f k8s/grafana

echo

#deploy prometheus
echo -e "${ORANGE}Deploying Prometheus"
tput sgr0
kubectl create -f ./k8s/prometheus

echo

#deploy kube-state-metrics
echo -e "${ORANGE}Deploying Kube State Metrics exporter"
tput sgr0
kubectl create -f ./k8s/kube-state-metrics

echo

#deploy ingress controller
echo -e "${BLUE}Deploying  K8S Ingress Controller"
tput sgr0
kubectl create -f ./k8s/ingress

echo

#wait for the ingress to become available.
echo -e "${BLUE}Waiting 10 seconds for the Ingress Controller to become available."
tput sgr0
sleep 10

#get ingress IP and hosts
PROM_INGRESS=$(kubectl get ing --namespace=monitoring)

echo 'Configure "/etc/hosts" or create DNS records for these hosts:' && printf "${RED}$PROM_INGRESS"

echo
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

echo -e "${GREEN}Waiting 5 seconds to establish the proxy connection"
tput sgr0
sleep 5
echo

curl 'http://admin:admin@127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"prometheus.monitoring.svc.cluster.local","type":"prometheus","url":"http://prometheus.monitoring.svc.cluster.local:9090","access":"proxy","isDefault":true}'
echo

#check datasources
echo -e "${GREEN}Checking datasource"
tput sgr0
curl 'http://admin:admin@127.0.0.1:3000/api/datasources'

echo

echo -e "${GREEN}Datasource imported"
tput sgr0

echo

echo -e "${RED}Killing background process."
tput sgr0

kill $!
echo

read -r -p "Do you want to proxy Grafana to localhost now? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo -e "${ORANGE}You can now access Grafana at http://127.0.0.1:3000"
    tput sgr0
    kubectl port-forward $GRAFANA_POD --namespace=monitoring 3000:3000
else
    echo -e "${GREEN}Complete"
fi
