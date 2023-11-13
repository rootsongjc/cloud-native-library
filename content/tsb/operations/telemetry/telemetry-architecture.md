---
title: Telemetry Architecture
description: Collecting telemetry from Service Bridge.
---

:::note
This page details how to collect telemetry necessary for operating Tetrate
Service Bridge, not applications managed by Tetrate Service Bridge.
:::

Tetrate Service Bridge uses the [Open Telemetry Collector](https://github.com/open-telemetry/opentelemetry-collector)
to simplify metrics collection. A standard deployment includes one in the
management plane and one alongside each onboarded control plane. Using the
Collector enables Tetrate Service Bridge to simplify telemetry collection per
cluster by only requiring operators to scrape a single component, rather than
all components.


![](../../assets/collector_architecture.svg)

## Management Plane

In the management plane there is a component called the `collector`. It is an
aggregator that exposes a single endpoint to scrape all management plane
components using Prometheus.

To see the output of this endpoint, it can be queried as follows:

```bash
kubectl port-forward -n <managementplane-namespace> svc/otel-collector 9090:9090 &
curl localhost:9090/metrics
```

Example output:
```text
...
# Metric from the API server in the management plane.
persistence_transaction_duration_count{component="tsb",plane="management"} 4605
```

## Control Plane

In each control plane there is also a `collector` that exposes a metrics
endpoint for components in its control plane. You can scrape this collector
using Prometheus in the same way as the management plane collector.

:::warning Open Telemetry collector
Although Open Telemetry collectors can forward metrics to other collectors, TSB
does not rely on forwarded metrics in production installations. Instead, we
recommend scraping each available collector locally.
:::


To see the output of this endpoint, use the following:

```bash
kubectl port-forward -n <controlplane-namespace> svc/otel-collector 9090:9090 &
curl localhost:9090/metrics
```
