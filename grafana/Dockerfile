FROM grafana/grafana:GRAFANA_VERSION
MAINTAINER Camil Blanaru <camil@edka.io>

ADD grafana-config/grafana.ini /etc/grafana/grafana.ini
ADD grafana-dashboards/* /var/lib/grafana/dashboards/

VOLUME ["/var/lib/grafana", "/var/log/grafana", "/etc/grafana"]
