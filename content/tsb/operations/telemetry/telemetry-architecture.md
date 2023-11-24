---
title: 遥测架构
description: 从 Service Bridge 收集遥测数据。
weight: 1
---

{{<callout note 注意>}}
本页面详细介绍了如何收集 Tetrate Service Bridge 运营所需的遥测数据，而不是由 Tetrate Service Bridge 管理的应用程序。
{{</callout>}}

Tetrate Service Bridge 使用 [Open Telemetry Collector](https://github.com/open-telemetry/opentelemetry-collector) 来简化指标收集。标准部署包括管理平面中的一个 Collector，以及每个已接入的控制平面旁边都有一个 Collector。使用 Collector 使 Tetrate Service Bridge 能够通过只需操作员抓取一个组件而不是所有组件，从而简化每个集群的遥测数据收集。

![](../../../assets/collector_architecture.svg)

## 管理平面

在管理平面中有一个名为 `collector` 的组件。它是一个聚合器，通过 Prometheus 公开了一个用于抓取所有管理平面组件的端点。

要查看此端点的输出，可以使用以下方式查询：

```bash
kubectl port-forward -n <managementplane-namespace> svc/otel-collector 9090:9090 &
curl localhost:9090/metrics
```

示例输出：
```text
...
# 来自管理平面中 API 服务器的指标。
persistence_transaction_duration_count{component="tsb",plane="management"} 4605
```

## 控制平面

在每个控制平面中，还有一个 `collector`，它公开了其控制平面中组件的指标端点。你可以以与管理平面 Collector 相同的方式使用 Prometheus 抓取此 Collector。

{{<callout warning "Open Telemetry Collector">}}
尽管 Open Telemetry 收集器可以将指标转发到其他收集器，但 TSB 不依赖于生产安装中转发的指标。相反，我们建议在每个可用的 Collector 上本地抓取指标。
{{</callout>}}

要查看此端点的输出，请使用以下命令：

```bash
kubectl port-forward -n <controlplane-namespace> svc/otel-collector 9090:9090 &
curl localhost:9090/metrics
```