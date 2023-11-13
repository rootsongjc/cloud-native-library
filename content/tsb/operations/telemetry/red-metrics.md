---
title: Sidecar RED Metrics
description: Collecting RED metrics from Envoy Sidecars in the Dataplane.
---

:::note
By default OAP in the Control Plane does not expose RED metrics.
To expose RED telemetry, set environment variable `SW_EXPORTER_ENABLE_OC=true` 
when starting OAP.
:::

TSB provides a single Prometheus-compatible endpoint to expose
sidecar-originated RED application metrics via the OAP service.
Each control plane cluster exposes a Prometheus-scraping endpoint to query with
the following command:

```bash
kubectl port-forward -n <controlplane-namespace> svc/oap 1234:1234 &
curl localhost:1234/metrics
```

Exported RED metrics include:

### Request status codes

```bash
# HELP tsb_oap_service_status_code The number of status code
# TYPE tsb_oap_service_status_code counter
tsb_oap_service_status_code{status="<STATUS|ALL>",svc="SERVICE_NAME",} COUNT
```

### Request latency

```bash
# HELP tsb_oap_service_latency_sum The sum of latency
# TYPE tsb_oap_service_latency_sum counter
tsb_oap_service_latency_sum{svc="SERVICE_NAME",} SUM
# HELP tsb_oap_service_latency_count The number of requests
# TYPE tsb_oap_service_latency_count counter
tsb_oap_service_latency_count{svc="SERVICE_NAME",} COUNT
```
