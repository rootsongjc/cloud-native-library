---
title: Sidecar RED 指标
description: 从 Dataplane 的 Envoy Sidecar 收集 RED 指标。
weight: 2
---

{{<callout note 注意>}}
默认情况下，控制平面中的 OAP 不会公开 RED 指标。
要公开 RED 遥测数据，请在启动 OAP 时设置环境变量 `SW_EXPORTER_ENABLE_OC=true`。
{{</callout>}}

TSB 提供一个与 Prometheus 兼容的单一端点，通过 OAP 服务公开来自 sidecar 的 RED 应用程序指标。每个控制平面集群都公开一个供 Prometheus 抓取的端点，可以使用以下命令查询：

```bash
kubectl port-forward -n <controlplane-namespace> svc/oap 1234:1234 &
curl localhost:1234/metrics
```

导出的 RED 指标包括：

### 请求状态码

```bash
# HELP tsb_oap_service_status_code 状态码的数量
# TYPE tsb_oap_service_status_code 计数器
tsb_oap_service_status_code{status="<STATUS|ALL>",svc="SERVICE_NAME",} COUNT
```

### 请求延迟

```bash
# HELP tsb_oap_service_latency_sum 延迟的总和
# TYPE tsb_oap_service_latency_sum 计数器
tsb_oap_service_latency_sum{svc="SERVICE_NAME",} SUM
# HELP tsb_oap_service_latency_count 请求的数量
# TYPE tsb_oap_service_latency_count 计数器
tsb_oap_service_latency_count{svc="SERVICE_NAME",} COUNT
```
