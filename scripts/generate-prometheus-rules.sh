#!/bin/bash

cat <<-EOF > ../manifests/prometheus/prometheus-k8s-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    prometheus: k8s
    role: alert-rules
  name: prometheus-k8s-rules
spec:
  groups:
EOF

for f in ../assets/prometheus/rules/*.rules
do
  cat $f | sed "s/^/  /g" >> ../manifests/prometheus/prometheus-k8s-rules.yaml
done
