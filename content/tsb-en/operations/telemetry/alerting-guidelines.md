---
title: Alerting Guidelines
description: Generic guidelines for setting up Tetrate Service Bridge monitoring alerts.
---

:::note
Tetrate Service Bridge collects a large number of metrics and the relationship
between those, and the threshold limits that you set will differ from
environment to environment. This document outlines the generic alerting
guidelines rather than providing an exhaustive list of alert configurations and
thresholds, since these will differ between different environments with
different workload configurations.
:::

## TSB Operational Status

### TSB Availability

The rate of successful requests to TSB API. This is an extremely user-visible
signal and should be treated as such.

Establish the `THRESHOLD` value from historical metric data captured within your
environment used as a baseline. A reasonable value for a first iteration would
be `0.99`.

Example PromQL expression:

```
sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_code="OK",
      grpc_type="unary",
      grpc_method!="SendAuditLog"
    }[1m]
  )
) BY (grpc_method) / sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_type="unary",
      grpc_method!="SendAuditLog"
    }[1m]
  )
) BY (grpc_method) < THRESHOLD
```

### TSB Request Latency

TSB gRPC API request latency metrics are intentionally not emitted due to high
metric cardinality.

### TSB Request Traffic

The raw rate of requests to TSB API. The monitoring value comes principally from
detecting outliers and unexpected behaviour, e.g. an unexpectedly high or low
request rate. To establish reasonable thresholds, it is vital to have a history
of metrics data to gauge the baseline.

Example PromQL expression:

```
sum(
  rate(
    grpc_server_handled_total{
      component="tsb",
      grpc_type="unary",
      grpc_method!="SendAuditLog"}[1m]
  )
) BY (grpc_method) < THRESHOLD
# or > THRESHOLD
```

### TSB Absent Metrics

TSB talks to its persistent backend even without constant external load. An
absence of requests reliably indicates an issue with TSB metrics collection, and
should be treated as a high-priority incident as the lack of metrics means the
loss of visibility into TSB's status.

Example PromQL expression:

```
sum(rate(persistence_operation[10m])) == 0
```

### Persistent Backend Availability

Persistent backend availability from TSB with no insight into the internal
Postgres operations.

TSB stores all of its state in the persistent backend and as such, its
operational status (availability, latency, throughput etc.) is tightly coupled
with the status of the persistent backend. TSB records the metrics for
persistent backend operations that may be used as a signal to alert on.

It is important to note that any degradation in persistent backend operations
will inevitably lead to overall TSB degradation, be it availability, latency or
throughput. This means that alerting on persistent backend status may be
redundant and the oncall person will receive two pages instead of one whenever
there is a problem with Postgres that requires attention. However, such a signal
still has significant value in providing important context to decrease the time
to triage the issue and address the root cause/escalate.

:::note
Treatment of "resource not found" errors: small number of "not found" responses
are normal because TSB, for the purposes of optimisation, often uses `Get`
queries instead of `Exists` in order to determine the resource existence.
However, a large rate of "not found" (404-like) responses likely indicates an
issue with the persistent backend setup.
:::

Example PromQL expressions:

- Queries:

```
1 - (
  sum(
    rate(
      persistence_operation{
        error!="", error!="resource not found"
      }[1m]
    )
) / sum(
    rate(persistence_operation[1m])
  ) OR on() vector(0)
) < THRESHOLD
```

- Too many "resource not found" queries:

```
( 
  sum(
    rate(persistence_operation{error="resource not found"}[1m])
  ) OR on() vector(0) / sum(
    rate(persistence_operation[1m])
  )
) > THRESHOLD # e.g. 0.50
```

- Transactions:

```
sum(
  rate(persistence_transaction{error=""}[1m])
) / sum(
  rate(persistence_transaction[1m])
) < THRESHOLD
```

### Persistent Backend Latency

The latency of persistent backend operations as recorded by the persistent
backend client (TSB). This latency effectively translates to user-seen latency
and as such is a vital signal.

The `THRESHOLD` value should be established from a historical metrics data used
as a baseline. A sensible value for a first iteration would be `300ms` 99th
percentile latency.

Example PromQL expressions:

- Queries

```
histogram_quantile(
  0.99,
  sum(rate(persistence_operation_duration_bucket[1m])) by (le, method)
) > THRESHOLD
```

- Transactions:

```
histogram_quantile(
  0.99,
  sum(rate(persistence_transaction_duration_bucket[1m])) by (le)
) > THRESHOLD
```

## XCP Operational Status

### Last Management Plane Sync

The max time elapsed since XCP Edge last synced with the management plane (XCP central)
for each registered cluster. This indicates how stale the configuration received from the
management plane is in a given cluster. A reasonable first iteration threshold
here is `30` (seconds).

Example PromQL expression:

```
time() - min(
  xcp_central_last_config_propagation_event_timestamp_ms{edge!=""} / 1000
) by (edge, status) > THRESHOLD
```

### XCP Edge Saturation

TSB Control Plane components are mostly CPU-constrained. Thus, the CPU
utilisation serves as an important signal and should be alerted on. Keep in mind
when choosing the alert THRESHOLDs that not only cloud providers tend to
overprovision CPU, but even hyperthreading may have negative effects on Linux
scheduler efficiency and lead to increased latencies/errors even at <~80% CPU
utilisation.

## Istio Operational Status

NB: this is not an exhaustive list of valuable signals that Istio Data Plane
provides. For more in-depth information please refer to:

- https://istio.io/latest/docs/examples/microservices-istio/logs-istio/
- https://istio.io/latest/docs/ops/best-practices/observability/
- https://istio.io/latest/docs/concepts/observability/

This document describes the absolute bare minimum alerting setup for Istio
service mesh.

### Proxy Convergence Time

Delay in seconds between config change and a proxy receiving all required
configuration. This is another part of configuration propagation latency.

Example PromQL expression:

```
histogram_quantile(
  0.99,
  sum(
    rate(
      pilot_proxy_convergence_time_bucket{
        cluster_name="$cluster"
      }[1m]
    )
  ) by (le)
) > THRESHOLD
```

### Istiod Error Rate

The error rate of various Istiod operations. To establish correct thresholds, it
is important to have the history of metrics data to gauge the baseline.

Example PromQL queries:

- Write Timeouts:

```
sum(
  rate(pilot_xds_write_timeout{cluster_name="$cluster"}[1m])
) > THRESHOLD
```

- Internal Errors:

```
sum(
  rate(pilot_total_xds_internal_errors{cluster_name="$cluster"}[1m])
) > THRESHOLD
```

- Config Rejections:

```
sum(
  rate(pilot_total_xds_rejects{cluster_name="$cluster"}[1m])
) > THRESHOLD
```

- Write Timeouts:

```
sum(
  rate(pilot_xds_write_timeout{cluster_name="$cluster"}[1m])
) > THRESHOLD
```

### Configuration Validation

The success rate of Istio configuration validation requests. Elevated errors
indicate that the Istio configuration generated by XCP Edge
is not valid and this should be urgently addressed.

Example PromQL expression:

```
sum(
  rate(galley_validation_passed{cluster_name="$cluster"}[1m])
) / (
  sum(
    rate(galley_validation_passed{cluster_name="$cluster"}[1m])
  ) + sum(
    rate(galley_validation_failed{cluster_name="$cluster"}[1m])
  )
) < THRESHOLD
```

## Capacity Planning and Resource Saturation

### TSB, XCP Central/Edge, OAP/Zipkin Saturation

TSB components are mostly CPU-constrained in addition to being constrained by
OAP/Zipkin memory utilisation depending on the amount of telemetry/traces they
collect. Thus, the CPU utilisation serves as an important signal and should be
alerted on. Even though it is not a direct symptom of an issue affecting users,
saturation provides a valuable signal that the system is
underprovisioned/oversaturated before it results in user impact.

Keep in mind when choosing the alert `THRESHOLDs` that not only cloud providers
tend to overprovision CPU, but even hyperthreading may have negative effects on
Linux scheduler efficiency and lead to increased latencies/errors even at <~80%
CPU utilisation.
