---
title: 监控指标
weight: 4
---

Tetrate 管理平面从每个接入的工作负载平台以及启用了适当 Skywalking 客户端的其他工作负载中收集指标和跟踪信息。这些指标存储在 ElasticSearch 数据库中，并通过 Tetrate UI 中的仪表板提供：

![仪表板 UI：服务实例指标](../images/metrics-1.png)

查看 [TSB](../../../quickstart/observability) 或 [TSE](https://docs.tetrate.io/service-express/getting-started/observability) 示例以获取更多详细信息。

用户需要访问 Tetrate UI 才能查看这些指标。在简单的单团队部署中可能是可行的，并且在 TSB 中，可以通过为应用程序所有者提供基于角色的访问权限，在非常大规模的情况下也可能是可行的，但在许多情况下，为你的应用程序所有者团队提供访问权限可能不是可行的或不适当的做法。

另一种方法是将 Tetrate 收集的指标导出到第三方仪表板，如 Grafana。这通常是提供大量用户访问 Tetrate 指标的最合适方式，特别是如果你已经有一个成熟的企业仪表板解决方案。

## 在第三方仪表板中公开 Tetrate 指标

你需要公开你的 TSE 指标并安排一个仪表板收集器来抓取并标记它们。以下资源可能会对你有所帮助：

- 了解 [Tetrate 指标架构](https://docs.tetrate.io/service-bridge/operations/telemetry)
- TSE [AWS 托管 Grafana 集成指南](https://docs.tetrate.io/service-express/integrations/grafana)
- TSB [Prometheus PromQL 指南](https://docs.tetrate.io/service-bridge/howto/promql-using-skywalking)
- TSB [New Relic 集成](https://docs.tetrate.io/service-bridge/operations/telemetry/new_relic)

## 获取 Tetrate 跟踪信息

Tetrate 管理平台从工作负载集群的交易中对跟踪信息进行采样，并将其存储在管理集群上。Tetrate 提供了 `tctl` 命令行工具中的功能来（a）离线复制集群和跟踪数据，并（b）检查此数据。

![tctl 工具用于检查性能数据](../images/tctl-service.png)

可以使用此功能，以便平台所有者可以对活动数据进行特权转储，并将其提供给应用程序所有者团队进行分析。

有关更多详细信息，请参阅有关 [如何识别和排查性能不佳的服务](../../../troubleshooting/identify-underperforming-services) 的文档。