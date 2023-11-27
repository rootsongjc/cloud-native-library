---
title: "边缘网关故障转移"
weight: 4
---

本指南使用了[扩展演示环境](../demo-2)中描述的演示环境，包括：

 * 两个 Edge 集群，位于 **region-1** 和 **region-2**
 * 两个工作负载集群，位于 **region-1** 和 **region-2**
 * 在工作负载集群中运行的 **BookInfo** 应用程序
 * 两个 Edge Gateway 负载均衡流量到工作负载集群

![Edge and Workload Load Balancing](../images/edge-workload-2.png)

在本指南中，我们将探讨当工作负载和 Edge 集群发生故障以及如何检测这些故障时会发生什么。然后，平台操作员可以使用这些信息配置一种分发流量到 Edge 集群的方式，例如基于 DNS 的 GSLB 解决方案。目标是保持尽可能高的可用性，并在可能的情况下优化流量路由。

## 生成和观察测试流量

请按以下方式测试演示环境：

<details>
<summary>验证所有组件</summary>

### 验证所有组件

为了测试所有流程（Edge Gateway 到两个工作负载集群的流程），我们将使用加权流量分布。将 **bookinfo-edge** 和 **bookinfo-edge-2** 编辑如下，并使用 **tctl** 应用更改：

```yaml
    routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                  weight: 50
                - name: cluster-2
                  weight: 50
```

请注意设置正确的 Kubernetes 上下文，获取每个 Edge Gateway 的地址：

```bash title="设置 kubectl 上下文为 edge-cluster 集群"
export GATEWAY_IP_1=$(kubectl -n edge get service edgegw -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo $GATEWAY_IP_1
```

```bash title="设置 kubectl 上下文为 edge-cluster-2 集群"
export GATEWAY_IP_2=$(kubectl -n edge get service edgegw-2 -o jsonpath="{.status.loadBalancer.ingress[0]['hostname','ip']}")
echo $GATEWAY_IP_2
```

在两个不同的终端窗口中，通过每个 Edge Gateway 发送对 **productpage.bookinfo** 服务的请求。注意使用 `?e1` 和 `?e2` 查询字符串来识别源 Edge Gateway：

```bash title="针对 edge-cluster 进行测试"
while sleep 1; do \
  curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP_1 \
    "http://bookinfo.tse.tetratelabs.io/productpage?e1" ; \
done 
```

```bash title="针对 edge-cluster-2 进行测试"
while sleep 1; do \
  curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP_2 \
    "http://bookinfo.tse.tetratelabs.io/productpage?e2" ; \
done 
```

如果你使用了在 [集群故障转移](../cluster-failover) 指南中描述的查看网关日志的技术，你应该观察到以下情况：

 * Edge Gateway 1（**edgegw**）接收到请求 `GET /productpage?e1`
 * Edge Gateway 2（**edgegw-2**）接收到请求 `GET /productpage?e2`
 * Ingress Gateway 1 和 2（**ingressgw-1** 和 **ingressgw-2**）接收到请求 `GET /productpage?e1` _和_ `GET /productpage?e2`

Tetrate UI 中的拓扑图将显示来自两个 Edge Gateway 到两个工作负载集群的流量。

</details>

<details>
<summary>测试工作负载集群故障转移</summary>

### 测试工作负载集群故障转移

将 **bookinfo-edge** 和 **bookinfo-edge-2** 配置更新为使用 [自动集群列表](../cluster-failover#auto-cluster-list) 配置：

```yaml
    routing:
        rules:
          - route:
              clusterDestination: {}
```

回想一下，这个配置会考虑所有工作正常的工作负载集群，并优先考虑如果它们可用的话，会优选位于同一地区的集群。

你的基准测试将显示，工作负载集群 1 仅从 Edge Gateway 1（对于 "2" 也是如此）接收请求，并且一旦数据同步，拓扑图也将反映这些数据。

#### 引发工作负载集群故障

可以通过删除 **cluster-1** 上的 **Gateway** 资源或将 **Ingress Gateway** 缩放到 0 个副本来引发 **cluster-1** 上的工作负载集群故障，如 [工作负载集群故障转移](../cluster-failover#test-failure-handling) 中所述。

例如，要删除 **cluster-1** 上的 **Gateway** 资源，可以使用 `tctl delete -f bookinfo-ingress-1.yaml`。

注意观察，现在两个 Edge Gateway 都会将流量发送到 **cluster-2**。故障转移已成功。
</details>

## Edge Gateway 故障转移

Edge Gateway 模式是一种两层模式，其中 Edge Gateway 在 Workload 集群的 Ingress Gateway 层之前提供第一层负载均衡。

与工作负载集群相比，Edge Gateway 的故障相对较少。Edge Gateway 组件具有简单且稳定的配置，由 Tetrate 管理平台完全管理，因此操作错误极不可能发生，并且 Edge Gateway 上的负载通常明显低于等效的工作负载集群。

你需要实施一种故障转移方法，以处理两种情况下的 Edge Gateway 停用：

 * Edge Gateway 完全故障或整个区域失败（情景 2）
 * 与 Edge Gateway 在同一区域的本地工作负载集群完全失败（情景 3，可选）

故障转移配置的目标是在这些故障情况下保持正常运行时间并最小化效率低下。在下面的解释中，我们将解释如何检测这些情况。

{{<callout note "每个区域一个 Edge Gateway">}}
为简单起见，这些情景考虑每个区域只有一个 Edge Gateway 的情况。可以扩展情景实施以涵盖在一个区域中有多个独立的 Edge Gateway 的情况。
{{</callout>}}

### 情景 0：正常的 Edge 和工作负载负载均衡

在正常运行期间，Edge 集群配置的目标是获得以下行为：

![情景 0：正常的 Edge 和工作负载负载均衡](../images/gslb-0.png)

使用 GSLB 解决方案来分发流量，可能还包括额外的近距离或加权负载均衡。每个 Edge Gateway 将流量分发到其本地区域的工作负载集群。

### 情景 1：本地工作负载集群部分故障

![情景 1：本地工作负载集群部分故障](../images/gslb-1.png)

_某个区域的一些工作负载集群故障_

每个 Edge Gateway 分发请求到所有正常工作的本地工作负载集群。GSLB 解决方案将继续将请求分发到所有 Edge Gateway。

客户端不受故障影响。

不需要进行故障转移操作，因为所有 Edge Gateway 都可以继续提供受影响的服务。我们假设每个区域都有足够的容量，可能已经启用了自动扩展以弥补活动集群的损失。

### 情景 2：Edge Gateway 或整个区域完全故障

![情景 2：Edge Gateway 或整个区域完全故障](../images/gslb-2.png)

_区域失败，要么是因为 Edge Gateway 故障，要么是因为整个基础设施失败_

GSLB 解决方案不应将流量发送到受影响区域的 Edge Gateway。

在基于 DNS 的 GSLB 中，任何已缓存到受影响区域的客户端都将遇到故障，直到刷新为止。

受影响区域的 Edge Gateway 必须在 GSLB DNS 解决方案中停用。

GSLB 解决方案会向其目标 IP 地址发送“合成事务”（即“测试请求”），以确定是否可以从该 IP 地址访问服务，并使用此信息来确定客户端提交 DNS 请求时哪些 IP 地址是候选的。

可以使用简单的 TCP、TLS 或 HTTPS 健康检查来检测故障，连接应该失败（超时）。也可以通过 **情景 3** 中描述的 HTTP(S) 健康检查的超时来检测故障。

### 情景 3：本地工作负载集群完全故障

![情景 3：本地工作负载集群完全故障](../images/gslb-3.png)

_一个区域中的所有工作负载集群都故障_

受影响区域的 Edge Gateway 分发请求到远程、正常工作的工作负载集群。此外，GSLB 解决方案不应将流量发送到受影响区域的 Edge Gateway。

在基于 DNS 的 GSLB 中，任何已缓存到受影响区域的客户端可能会因内部跨区域跳跃而遇到性能下降（延迟）。

正如我们在[工作负载集群故障转移](../cluster-failover)解释中观察到的，受影响区域的 Edge Gateway 将继续运行，并将请求转发到远程集群。

尽管如此，受影响区域的 Edge Gateway 应该在 GSLB DNS 解决方案中停用。这可以减少区域内流量，从而产生延迟惩罚和可能的传输成本惩罚。

### 每个服务的健康检查

我们希望为每个服务实施一个健康检查（HC），具有以下行为：

 * 对区域中的 Edge Gateway 发出的 HC 请求应路由到同一区域的正常工作工作负载集群
 * 如果区域中的所有工作负载集群都失败，HC 请求应失败，即使客户端请求将被转发到远程区域并成功执行

这种行为足以检测**情景 2**和**情景 3**中的故障。

#### X-HealthCheck: true

Edge Gateway 需要能够区分常规请求（在所有集群之间进行负载均衡的请求）和只能在本地集群之间进行负载均衡的 HC 请求。我们可以通过在 HC 请求中添加特定标头，例如 `X-HealthCheck: true`，来实现这一点。你需要在 GSLB 解决方案中配置健康检查以添加此标头。

然后，只需配置 Edge Gateway，使其将 `X-HealthCheck: true` 请求路由到本地集群。

#### 在 Gateway 资源中使用规则

在 **bookinfo-edge** **Gateway** 资源中添加以下附加规则：

```yaml title="bookinfo-edge.yaml"
apiVersion: gateway.tsb.tetrate.io/v2
kind: Gateway
metadata:
  organization: tse
  tenant: tse
  workspace: edge-ws
  group: edge-gwgroup
  name: bookinfo-edge
spec:
  workloadSelector:
    namespace: edge
    labels:
      app: edgegw
  http:
    - hostname: "bookinfo.tse.tetratelabs.io"
      name: bookinfo
      port: 80
      routing:
        rules:
# highlight-start
          - match:
            - headers:
                x-healthcheck:
                  exact: "true"
            route:
              clusterDestination:
                clusters:
                - name: cluster-1
# highlight-end
          - route:
              clusterDestination: {}
```

### 测试健康检查

针对 **cluster-edge** 上的 Edge Gateway 提交一个 HC 请求。注意使用查询字符串 `?HC` 以便我们可以识别 HC 请求：

```bash
curl -s --connect-to bookinfo.tse.tetratelabs.io:80:$GATEWAY_IP_1 \
    -H "X-HealthCheck: true" \
    "http://bookinfo.tse.tetratelabs.io/productpage?HC"
```

在正常运行中，健康检查将成功。

#### 模拟故障

通过删除 **cluster-1** 上的 Gateway 资源来模拟故障。如果你正在运行上面描述的测试，你将观察到常规流量不受影响，并且 Edge Gateway 开始将这些请求转发到工作负载集群 **cluster-2**。

重新播放 HC 请求。HC 请求将失败，返回 `503` 状态码和响应体 `no healthy upstreams`。

### 结论

你可以使用每个服务的健康检查来触发故障转移（和恢复），适用于**情景 2**和**情景 3**。

## 我们取得了什么成就？

我们观察到 Tetrate 平台在**Edge 集群**或**工作负载集群**出现故障或其托管服务出现故障的一系列情景中的故障检测和恢复行为。我们优化了故障转移行为，并开发了用于外部 GSLB 解决方案的健康检查，以最小化或消除对服务最终用户的任何影响。

你需要为每个区域的 Edge Gateway 在 **Gateway** 资源中添加适当的规则实现，以将 HC 请求路由到本地区域的工作负载集群。

你还可以通过以下方式减轻故障的一些影响：

 * 遵循 [Operations Tips](../operations) 文档中的最佳实践，解释如何以受控方式将资源停用
 * 减小 TTL 并调整 GSLB 解决方案以最小化受影响客户的停机时间
 * 参考 GSLB 提供商的最佳实践指南，以最小化在意外事件发生时的停机时间
 * 请联系 Tetrate 支持，以获取有关微调 Gateway 配置以控制故障检测和故障转移的附加信息

{{<callout note "常见的 DNS 缓存行为">}}
对于已失败的 Edge Gateway 的缓存 DNS 条目的影响可能会有所不同。简单的客户端会缓存该条目，直到其 TTL 过期（通常为 30 秒）。现代客户端，包括所有现代 Web 浏览器，在响应此情况时具有更复杂的行为。如果无法连接，客户端可能会自动刷新其 DNS 缓存，并且如果 DNS 服务器以 RR（轮询）响应，则可能会重试其他位置。请参考你的 GSLB 提供商的特定最佳实践指南。
{{</callout>}}