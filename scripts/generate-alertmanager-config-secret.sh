#!/bin/bash
os=$(uname)
if [[ $os == "Darwin" ]]; then
  b64="base64"
else
  b64="base64 --wrap=0"
fi

# For MacOS that support --wrap=0 base64 return a multiline string
if [[ $(cat ../assets/alertmanager/alertmanager.yaml | $b64 | wc -l) > 1 ]]; then
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
