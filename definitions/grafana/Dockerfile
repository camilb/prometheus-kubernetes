FROM grafana/grafana:4.1.0-beta1
MAINTAINER Camil Blanaru <camil@edka.io>

ADD grafana-config/grafana.ini /etc/grafana/grafana.ini
ADD grafana-dashboards/* /var/lib/grafana/dashboards/

VOLUME ["/var/lib/grafana", "/var/log/grafana", "/etc/grafana"]
