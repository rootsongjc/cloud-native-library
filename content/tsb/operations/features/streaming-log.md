---
title: 流式服务日志
description: 启用服务流式日志以显示工作负载日志。
weight: 2
---

{{<callout warning "Alpha 功能">}}
流式服务日志是一个 Alpha 功能，不建议在生产环境中使用。
{{</callout>}}

TSB 具有直接从 TSB UI 查看服务日志的功能。使用此功能，你将能够查看应用程序和 sidecar 的几乎实时日志，以进行故障排除。

{{<callout note 日志存储>}}
TSB **不会**将任何日志存储在存储系统中。日志直接从集群流式传输到管理平面。
{{</callout>}}

## 管理平面

要在管理平面中启用服务日志流式传输，请在 `ManagementPlane` CR 或 Helm 值中的 oap 组件下添加 `streamingLogEnabled: true` ，然后应用。

```yaml
spec:
  hub: <registry_location>
  organization: <organization>
    ...
  components:
    ...
    oap:
      streamingLogEnabled: true  
```

## 控制平面

对于每个注册的集群，请在 `ControlPlane` CR 或 Helm 值中的 oap 组件下添加 `streamingLogEnabled: true` ，然后应用。

```yaml
spec:
  hub: <registry_location>
  managementPlane:
    ...
  telemetryStore:
    elastic:
      ...
  components:
    ...
    oap:
      streamingLogEnabled: true
```

## 流式服务日志 UI

要在 TSB UI 中查看服务日志，请转到服务并选择受控服务。受控服务是网格的一部分，并且具有我们可以配置代理的服务。

你将看到 Logs 选项卡，并且可以选择要查看其日志的容器，然后单击 Start 按钮开始流式传输日志。

下图显示了具有 sidecar 的服务的服务日志。你可以选择最多两个容器，因此将能够同时查看服务和 sidecar 日志。

![](../../../assets/operations/streaming-log-service.png)

下图显示了 TSB 网关的服务日志。

![](../../../assets/operations/streaming-log-gateway.png)