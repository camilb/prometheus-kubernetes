#!/bin/bash

cat <<-EOF > ../manifests/prometheus/prometheus-k8s-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-k8s-rules
  namespace: monitoring
  labels:
    role: prometheus-rulefiles
    prometheus: k8s
data:
EOF

for f in ../assets/prometheus/rules/*.rules
do
  echo "  $(basename $f): |+" >> ../manifests/prometheus/prometheus-k8s-rules.yaml
  cat $f | sed "s/^/    /g" >> ../manifests/prometheus/prometheus-k8s-rules.yaml
done
