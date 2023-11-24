---
title: New Relic 集成
description: 在 New Relic 中分析服务网格指标。
weight: 6
---

New Relic 的流行软件分析平台使企业能够监视其应用程序、服务器和数据库的健康和性能。它从各种来源收集和分析数据，包括应用程序日志、服务器指标和用户交互，以提供详细的洞察和指标。

Tetrate 的丰富的可观测性数据可以与 New Relic 平台无缝集成。本文介绍了如何在 New Relic 中使 Istio 和 Tetrate Service Bridge 的遥测数据可用。有关与应用程序负载相关的指标，请参阅[New Relic 文章](https://newrelic.com/blog/how-to-relic/monitoring-istio-service-mesh)，该文章描述了 Istio 数据平面指标的检索。

{{<callout note 注意>}}
下面的步骤经过验证，但一些客户可能需要额外的定制来满足其自定义的 New Relic 设置。
{{</callout>}}

## 数据流

下面的图表显示了 Tetrate Service Bridge 导出到 New Relic 的指标工作流程处理。

![Tetrate Service Bridge 到 New Relic 的工作流程图](../images/tsb-to-newrelic.png)

每个 Tetrate Service Bridge 控制平面都使用[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)来收集一组高级指标，并将它们聚合在全局 TSB 管理平面中，以及与管理平面中的活动相关的其他指标数据。一旦聚合完成，OpenTelemetry Collector 可以用于直接导出数据到 New Relic。

### 配置 Tetrate Service Bridge 以适用于 New Relic

上述所述的 Tetrate 的遥测数据收集和聚合是一个开箱即用的 TSB 配置，不需要任何更改。按照以下步骤将 Tetrate 的数据与 New Relic 集成。

#### New Relic 集成

使用以下步骤配置 TSB 管理平面中的 OpenTelemetry Collector，以通过 OTLP 导出器将数据写入 New Relic 端点。

基本步骤如下，具体说明如下：

- **步骤 1：** 创建一个从 TSB 管理平面复制的 OpenTelemetry `configMap`，并将其修改为启用 OTLP 导出器。
- **步骤 2：** 配置在 Tetrate Service Bridge 管理平面中运行的 OpenTelemetry Collector，以使用上一步创建的 `configMap`。

有关更多信息，请参阅[OTLP 导出器项目页面](https://aws-otel.github.io/docs/components/otlp-exporter#new-relic)和[New Relic 文档](https://docs.newrelic.com/docs/kubernetes-pixie/kubernetes-integration/advanced-configuration/link-otel-applications-kubernetes/#otlp-exporter)。

{{<callout note "可选的 New Relic Kubernetes 集成">}}
New Relic 文档建议在 Kubernetes 集群内部部署 New Relic 集成。这一步骤不需要将 Tetrate Service Bridge 指标传递到 New Relic 平台。
{{</callout>}}

##### 步骤 1：创建 OpenTelemetry `configMap`

下载并保存[`此配置映射 yaml 文件，命名为 otel-cm-tsb.yaml`](../../../assets/operations/otel-cm-tsb.yaml)。

编辑文件，将 `<api key>` 字段替换为 New Relic 提供的密钥（如下图所示，请识别 `INGEST - LICENSE` 密钥）：

![New Relic UI 中的 INGEST - LICENSE 密钥](../images/new-relic-key.png)

使用以下命令将配置应用到你的 Kubernetes 集群：

```bash
kubectl apply -f otel-cm-tsb.yaml
```

##### 步骤 2：配置 Tetrate Service Bridge OpenTelemetry Collector

为了指向前一步骤创建的 `configMap`，需要使用以下命令对 TSB 管理平面自定义资源配置进行修补。

{{<callout note "Kubernetes 上下文">}}
确保你当前的 Kubernetes 上下文设置为运行 Tetrate Service Bridge 管理平面的集群。
{{</callout>}}

{{<callout note "TSB 管理平面命名空间">}}
请注意，默认情况下，`tsb` 是管理平面的命名空间。如果你的 TSB 管理平面部署在不同的命名空间中，请相应地修改上述命令。
{{</callout>}}

```bash
kubectl patch managementplane managementplane -n tsb \
    --patch '{"spec":{"components":{"collector":{"kubeSpec":{"overlays":[{"apiVersion": "apps/v1","kind": "Deployment","name": "otel-collector","patches":[{"path":"spec.template.spec.volumes[0].configMap.name","value":"otel-collector-modified"}]}]}}}}}' \
    --type merge
```

### 验证 New Relic 集成

Tetrate 维护了一组预构建的仪表板，可供使用作为起点；用户还可以使用自定义 New Relic 查询构建自己的仪表板集。

以下查询将确认 New Relic 集成是否正常工作：

```
SELECT rate(sum(envoy_cluster_internal_upstream_rq), 1 SECONDS) FROM Metric WHERE ((envoy_response_code RLIKE '2.*|3.*|401') AND (component = 'front-envoy')) SINCE 60 MINUTES AGO UNTIL NOW FACET envoy_cluster_name LIMIT 100 TIMESERIES 60000 SLIDE BY 30000
```

![New Relic 中的 TSB 指标](../images/new-relic-validate.png)

### 总结

本页面描述了将 Tetrate Service Bridge 指标与 New Relic 平台集成所需的步骤。如果需要进一步的信息或帮助，请联系 Tetrate 支持。