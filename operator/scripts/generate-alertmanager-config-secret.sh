#!/bin/bash

cat <<-EOF >  ../manifests/alertmanager/alertmanager.cm.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-main
data:
  alertmanager.yaml: $(cat ../assets/alertmanager/alertmanager.yaml | base64)
EOF
