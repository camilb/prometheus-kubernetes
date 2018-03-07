#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

echo -e "${BLUE}Do you want to set up an Nginx Ingress Controller?"
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
      kubectl apply -f ./rbac.yaml
  else
      echo -e "${GREEN}Skipping RBAC configuration"
  fi
  tput sgr0

  echo
  echo -e "${GREEN}Type your domain name."
  tput sgr0

  read -p "domain: " domain_name

  sed -i -e 's/domain_name/'"$domain_name"'/g' ./ingress.yaml

  #Set username and password for basic-auth
  echo
  echo -e "${BLUE}Please set the username and password for basic-auth to prometheus and alertmanager:"
  tput sgr0
  read -p "Set username [monitor]: " username
  htpasswd -c auth ${username:-'monitor'}

  #base64 encode the basic-auth and set the secret
  BASIC_AUTH=$(cat ./auth | base64)
  sed -i -e 's/htpasswd/'"$BASIC_AUTH"'/g' ./basic-auth.secret.yaml

  #deploy ingress controller
  echo
  echo -e "${BLUE}Deploying  K8S Ingress Controller"
  tput sgr0
  kubectl apply -f ./nginx-controller.yaml

  #ingress
  echo
  echo -e "${BLUE}Deploying  K8S Ingress Controller"
  tput sgr0
  kubectl apply -f ./basic-auth.secret.yaml
  kubectl apply -f ./ingress.yaml

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

    sed -i -e 's/domain_name/'"$domain_name"'/g' ./ingress.yaml

    #Set username and password for basic-auth
    echo
    echo -e "${BLUE}Please set the username and password for basic-auth to prometheus and alertmanager:"
    tput sgr0
    read -p "Set username [monitor]: " username
    htpasswd -c auth ${username:-'monitor'}

    #base64 encode the basic-auth and set the secret
    BASIC_AUTH=$(cat ./auth | base64)
    sed -i -e 's/htpasswd/'"$BASIC_AUTH"'/g' ./basic-auth.secret.yaml
    echo
    echo -e "${BLUE}Creating Ingress"
    tput sgr0
    kubectl apply -f ./basic-auth.secret.yaml
    kubectl apply -f ./ingress.yaml
  fi
fi

#remove  "sed" generated files
rm ./*.yaml-e

echo
#cleanup
echo -e "${GREEN}Cleaning modified files"
tput sgr0

rm auth
git checkout *

echo
echo -e "${GREEN}Done"
tput sgr0
