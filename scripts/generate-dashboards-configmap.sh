#!/bin/bash

cat <<-EOF > ../manifests/grafana/grafana-dashboards.cm.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboards
  namespace: monitoring
data:
EOF

for f in ../assets/grafana/*-dashboard.json
do
  echo "  $(basename $f): |+" >> ../manifests/grafana/grafana-dashboards.cm.yaml
  ./wrap-dashboard.sh $f | sed "s/^/    /g" >> ../manifests/grafana/grafana-dashboards.cm.yaml
done

for f in ../assets/grafana/*-datasource.json
do
  echo "  $(basename $f): |+" >> ../manifests/grafana/grafana-dashboards.cm.yaml
  cat $f | sed "s/^/    /g" >> ../manifests/grafana/grafana-dashboards.cm.yaml
done
