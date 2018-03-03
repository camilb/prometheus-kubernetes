#!/bin/bash

# Check whether the base64 binary is GNU or BSD
echo "" | base64 --wrap=0 > /dev/null 2>&1
if [ "$?" -eq 0 ]; then
    b64="base64 --wrap=0"
else
    b64="base64"
fi

cat <<-EOF >  ../manifests/alertmanager/alertmanager.cm.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
data:
  alertmanager.yaml: $(cat ../assets/alertmanager/alertmanager.yaml | $b64)
EOF
