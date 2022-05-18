---
weight: 70
title: 可观察性
date: '2022-05-18T00:00:00+08:00'
type: book
icon: book-open
icon-pack: fas
---

在本章中，我们将学习一些监控（Prometheus）、追踪（Zipkin）和数据可视化工具（Grafana）。

## 什么是可观察性？

由于采用了 sidecar 部署模式，即 Envoy 代理运行在应用实例旁边并拦截流量，这些代理也收集指标。

Envoy 代理收集的指标可以帮助我们获得系统状态的可见性。获得系统的这种可见性是至关重要的，因为我们需要了解正在发生的事情，并授权运维人员对应用程序进行故障排除、维护和优化。

Istio 生成三种类型的遥测数据，为网格中的服务提供可观察性：

- 指标度量（Metric）
- 分布式跟踪
- 访问日志

## 指标度量

Istio 基于四个黄金信号生成指标：延迟、流量、错误和饱和度。

延迟表示服务一个请求所需的时间。这个指标应该分成成功请求（如 HTTP 200）和失败请求（如 HTTP 500）的延迟。

流量是衡量对系统的需求有多大，它是以系统的具体指标来衡量的。例如，每秒的 HTTP 请求，或并发会话，每秒的检索量，等等。

错误用来衡量请求失败的比率（例如 HTTP 500）。

饱和度衡量一个服务中最紧张的资源有多满。例如，线程池的利用率。

这些指标是在不同的层面上收集的，首先是最细的，即 Envoy 代理层面，然后是服务层面和控制面的指标。

### 代理级指标

生成指标的一个关键角色是 Envoy，它生成了一套关于所有通过代理的流量的丰富指标。使用 Envoy 生成的指标，我们可以以最低的粒度来监控服务网格，例如 Envoy 代理中的 inidivdual 监听器和集群的指标。

作为网格运维人员，我们有能力控制在每个2工作负载实例中生成和收集哪些 Envoy 指标。

下面是几个代理级指标的例子。

```
envoy_cluster_internal_upstream_rq{response_code_class="2xx",cluster_name="xds-grpc"} 7163
envoy_cluster_upstream_rq_completed{cluster_name="xds-grpc"} 7164
envoy_cluster_ssl_connection_error{cluster_name="xds-grpc"} 0
envoy_cluster_lb_subsets_removed{cluster_name="xds-grpc"} 0
envoy_cluster_internal_upstream_rq{response_code="503",cluster_name="xds-grpc"} 1
```

> 注意你可以从每个 Envoy 代理实例的 `/stats` 端点查看代理级指标。

### 服务级指标

服务级别的指标涵盖了我们前面提到的四个黄金信号。这些指标使我们能够监控服务与服务之间的通信。此外，Istio 还提供了一组仪表盘，我们可以根据这些指标来监控服务行为。

就像代理级别的指标一样，运营商可以自定义收集哪些服务级别的指标。

默认情况下，Istio 的标准指标集会被导出到 Prometheus。

下面是几个服务级指标的例子。

#### 控制平面度量

Istio 也会发射控制平面指标，可以帮助监控 Istio 的控制平面和行为，而不是用户服务。

输出的控制平面指标的完整列表可以在这里找到。

控制平面指标包括冲突的入站/出站监听器的数量、没有实例的集群数量、被拒绝或被忽略的配置等指标。

{{< cta cta_text="阅读本章" cta_link="telemetry-api" >}}