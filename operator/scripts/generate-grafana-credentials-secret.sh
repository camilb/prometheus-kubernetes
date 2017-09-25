#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 user password"
    exit 1
fi

os=$(uname)
if [[ $os == "Darwin" ]]; then
  b64="base64"
else
  b64="base64 --wrap=0"
fi

user=$1
password=$2

cat <<-EOF
apiVersion: v1
kind: Secret
metadata:
  name: grafana-credentials
data:
  user: $(echo -n ${user} | $b64)
  password: $(echo -n ${password} | $b64)
EOF
