groups:
- name: node.rules
  rules:
  - alert: NodeExporterDown
    expr: absent(up{job="node-exporter"} == 1)
    for: 10m
    labels:
      severity: warning
    annotations:
      description: Prometheus could not scrape a node-exporter for more than 10m,
        or node-exporters have disappeared from discovery.
      summary: node-exporter cannot be scraped
  - alert: K8SNodeOutOfDisk
    expr: kube_node_status_condition{condition="OutOfDisk",status="true"} == 1
    labels:
      service: k8s
      severity: critical
    annotations:
      description: '{{ $labels.node }} has run out of disk space.'
      summary: Node ran out of disk space.
  - alert: K8SNodeMemoryPressure
    expr: kube_node_status_condition{condition="MemoryPressure",status="true"} ==
      1
    labels:
      service: k8s
      severity: warning
    annotations:
      description: '{{ $labels.node }} is under memory pressure.'
      summary: Node is under memory pressure.
  - alert: K8SNodeDiskPressure
    expr: kube_node_status_condition{condition="DiskPressure",status="true"} == 1
    labels:
      service: k8s
      severity: warning
    annotations:
      description: '{{ $labels.node }} is under disk pressure.'
      summary: Node is under disk pressure.
  - alert: NodeCPUUsage
    expr: (100 - (avg by (instance) (irate(node_cpu{job="node-exporter",mode="idle"}[5m])) * 100)) > 90
    for: 30m
    labels:
      severity: warning
    annotations:
      summary: "{{$labels.instance}}: High CPU usage detected"
      description: "{{$labels.instance}}: CPU usage is above 90% (current value is: {{ $value }})"
  - alert: NodeMemoryUsage
    expr: (((node_memory_MemTotal-node_memory_MemFree-node_memory_Cached)/(node_memory_MemTotal)*100)) > 90
    for: 30m
    labels:
      severity: warning
    annotations:
      summary: "{{$labels.instance}}: High memory usage detected"
      description: "{{$labels.instance}}: Memory usage is above 90% (current value is: {{ $value }})"
