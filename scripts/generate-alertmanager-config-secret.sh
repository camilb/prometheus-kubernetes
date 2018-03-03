#!/bin/bash
os=$(uname)
if [[ $os == "Darwin" ]]; then
  BASE64_VERSION=$(base64 --version 2> /dev/null | awk 'NR==1')
  case $BASE64_VERSION in
    "base64 1."*)
    echo "You are using an outdated version of base64";
    echo "Please remove the brew installed version and run this script again"
    ;;
    "base64 (GNU coreutils)"*)
    b64="base64 --wrap=0";
    ;;
    "")
    b64="base64";
    ;;
  esac
else
  b64="base64 --wrap=0"
fi

cat <<-EOF >  ../manifests/alertmanager/alertmanager.cm.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
data:
  alertmanager.yaml: $(cat ../assets/alertmanager/alertmanager.yaml | $b64)
EOF
