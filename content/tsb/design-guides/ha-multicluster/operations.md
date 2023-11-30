---
title: 运维和测试高可用性与故障转移
weight: 5
---

本文档解释了如何测试故障转移，并运维任务，如排空和恢复集群。

平台 Operator 可能需要手动执行以下操作：

 * 在执行维护之前，将工作负载集群排除在旋转之外，以允许现有请求完成
 * 在执行维护之前，将 Edge Gateway 排除在旋转之外，以允许缓存的 DNS 记录超时
 * 定义一个区域为“活动”或“被动”（Tetrate 默认模型是全活动）

[工作负载集群故障转移](../cluster-failover) 和 [Edge Gateway 故障转移](../edge-failover) 指南中的示例演示了以可控且可预测的方式将组件排除在服务之外的各种方式，最佳实现将受到特定拓扑和 GSLB 解决方案选择的影响。

### 将工作负载集群排除在旋转之外

#### 选项 1：编辑 Edge Gateway 配置

编辑 Edge Gateway 集群列表不会影响服务可用性。已删除集群的请求将允许完成，并且新的请求将不会路由到该集群。

你需要在 Edge Gateway 的 **Gateway** 配置中显式列出工作负载集群：

```yaml
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination: {}
```

```yaml
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - name: bookinfo
      port: 80
      hostname: bookinfo.tse.tetratelabs.io
      routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                - name: cluster-2
```

#### 选项 2：删除工作负载集群上的 Gateway 资源

删除工作负载集群上的 **Gateway** 资源。

Tetrate 平台将立即更新 Edge Gateway 配置，从已删除 **Gateway** 资源中的主机名的负载均衡集中移除该集群。

停机时间不太可能出现，并且 Envoy Gateway 将尝试负载均衡到其他集群，如果它观察到失败（通常是 `404 Not Found` 响应）。

#### 选项 3：取消配置工作负载集群上的 Ingress Gateway

删除工作负载集群上的 **IngressGateway** 资源。这将取消配置 Ingress Gateway。

Tetrate 平台将立即更新 Edge Gateway 配置，从已删除 **Gateway** 资源中的主机名的负载均衡集中移除该集群。

可能会出现短暂的停机时间，如果 Envoy Gateway 观察到故障（通常是连接超时），它将尝试负载均衡到其他集群。这可能会导致未完成的请求延迟。

### 将区域排除在旋转之外

交通分布到各个区域的 Edge Gateway 受 GSLB 解决方案的控制。

#### 选项 1：配置 GSLB 解决方案

使用 GSLB 提供商的 API，并按照其最佳实践指南，将所需的区域（Edge Gateway）排除在旋转之外。

#### 选项 2：触发健康检查

此选项需要额外的配置，但允许管理员在无需与第三方 GSLB API 交互的情况下将区域排除在旋转之外。

核心原则是使用健康检查，并在希望将区域下线时引发该健康检查失败。常规请求不受影响，因此对于已缓存 Edge Gateway 在该区域的 DNS 记录的客户端，不会发生任何服务中断或增加的延迟。

[Edge Gateway 故障转移](../edge-failover) 指南解释了健康检查的原理，其中一个特殊标记的请求（例如带有 `X-HealthCheck: true` 标头的请求）接收到触发 GSLB 解决方案中的故障转移或恢复的自定义响应。可以以许多方式实现健康检查，例如编辑 Edge Gateway 资源以返回错误，或使用特殊的 URL，将其路由到工作负载集群上的金丝雀服务（例如 http

bin）。根据你的需求和与 Tetrate 平台互动的期望方式，请参考 Tetrate 专业服务以获得具体建议。