---
title: 工作负载集群故障转移
weight: 2
---

本指南使用在 [演示环境](../demo-1) 中描述的环境，即：

 * 一个位于 **region-1** 的 Edge 集群
 * 两个工作负载集群，分别位于 **region-1** 和 **region-2**
 * 在工作负载集群中运行的 **BookInfo** 应用程序
 * 一个 Edge Gateway 用于负载均衡流量到工作负载集群

![Edge 和工作负载负载均衡](../images/edge-workload.png)

一个简单的 HTTP 请求被路由到 Edge Gateway，然后转发到其中一个工作负载集群，并生成成功的响应：

```bash
curl http://bookinfo.tse.tetratelabs.io/productpage
```

在本指南中，我们将查看系统在工作负载集群发生故障时的故障转移行为。

## 生成和观察测试流量

生成一定数量的测试流量对于系统非常有帮助。适用于基准测试的工具，如 **wrk**，非常适合这个任务：

```bash title="生成 30 秒的流量突发，每次一个请求"
while sleep 1; do \
   wrk -c 1 -t 1 -d 30 http://bookinfo.tse.tetratelabs.io/productpage ; \
done
```

观察 Edge Gateway 上的流量，方法如下：

```bash title="设置 kubectl 上下文/别名到 cluster-edge 集群"
kubectl logs -f -n edge -l=app=edgegw | cut -c -60
```

使用另外两个终端窗口，观察每个 Ingress Gateway 上的流量，方法如下：

```bash title="设置 kubectl 上下文/别名到 cluster-1 集群"
kubectl logs -f -n bookinfo -l=app=ingressgw-1 | cut -c -60
```

```bash title="设置 kubectl 上下文/别名到 cluster-2 集群"
kubectl logs -f -n bookinfo -l=app=ingressgw-2 | cut -c -60
```

![观察测试流量](../images/loadgen.gif)

## 配置 Edge Gateway

Edge Gateway 使用 **Gateway** 资源进行配置，具有以下选项：

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
# highlight-start
              clusterDestination:
                clusters:
                - name: cluster-1
                  weight: 50
                - name: cluster-2
                  weight: 50
# highlight-end
```

### 自动集群列表

_自动集群列表配置是一种简单有效的配置，需要最少的管理工作_

```yaml
      routing:
        rules:
          - route:
              clusterDestination: {}
```

使用自动集群列表，Tetrate 平台将确定适合的目标集群。它通过比较 Edge **Gateway** 资源中的主机名与工作负载集群 **Gateway** 资源中的匹配主机名来实现。如果向环境中添加或删除了工作负载集群和 Gateway 资源，则 Edge Gateway 将自动重新配置。

Edge Gateway 仅将流量引导到位于**相同地区**的工作负载集群上的 Ingress Gateway。这种基于地理位置的选择旨在最小化延迟并避免昂贵的跨地区流量。

如果位于同一地区的所有 Ingress Gateway 失败，那么 Edge Gateway 将在远程地区的其余工作负载集群之间共享流量。健康检查基于对 Ingress Gateway pods 的异常检测。

### 命名集

群列表

_命名集群列表的功能类似于自动集群列表，但只考虑列表中命名的工作负载集群_

```yaml
      routing:
        rules:
          - route:
              clusterDestination:
                clusters:
                - name: cluster-1
                - name: cluster-2
```

使用命名集群列表，Tetrate 平台将流量引导到指定的工作负载集群上的 Ingress Gateway。平台会验证这些集群是否具有 Ingress Gateway，并具有包含匹配主机名的 **Gateway** 资源。

Edge Gateway 将流量引导到位于**相同地区**的工作负载集群上的 Ingress Gateway。这种基于地理位置的选择旨在最小化延迟并避免昂贵的跨地区流量。

如果位于同一地区的所有 Ingress Gateway 失败，那么 Edge Gateway 将在远程地区的其余工作负载集群之间共享流量。健康检查基于对 Ingress Gateway pods 的异常检测。

### 权重集群列表

_使用权重来协调流量从一个集群逐渐转移到另一个集群_

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

使用权重列表，Tetrate 平台将根据配置的权重严格分配流量到集群中。不执行健康检查，因此如果集群没有正常工作的 Ingress Gateway，则定向到该集群的请求将生成 '**503 no healthy upstream**' 或类似的错误响应。

权重旨在在受控情况下使用，用于金丝雀测试新集群。


## 测试故障处理

你可以按照以下方式测试故障处理：

 * 运行负载生成器，并按上述方式查看 Gateway 日志
 * 应用所需的 Edge Gateway 配置：`tctl apply -f bookinfo-edge.yaml`

现在，你可以引发故障并执行以下操作：

 1. 观察每个 Ingress Gateway 上的流量分布
 2. 观察成功的请求（状态码 200）和错误（503 或其他状态码）

请注意，在使用权重与集群时，故障转移不会发生。

### 移除 Gateway 资源

引发故障的最简单方法是删除工作负载集群上的 **Gateway** 资源。Tetrate 平台将确定哪些 Ingress Gateway 管理着所需主机名的流量，并相应地配置 Edge Gateway：

 * 要删除 **Gateway** 资源：`tctl delete -f bookinfo-ingress-1.yaml`
 * 要恢复 **Gateway** 资源：`tctl apply -f bookinfo-ingress-1.yaml`

此方法模拟了操作性故障，其中 **Gateway** 资源未应用到工作正常的集群，或者删除了服务及其相关的 **Gateway** 资源。

### 缩放 Ingress Gateway

测试故障处理的另一种方法是将 Ingress Gateway 服务缩放为 0 个副本：

 * 通过将工作负载集群 Ingress Gateway 缩放为 0 个副本来引发故障：`kubectl scale deployment -n bookinfo ingressgw-2 --replicas=0`
 * 通过将其缩放为 1 个副本来恢复 Ingress Gateway

故障转移的速度取决于异常检测的速度以及 Tetrate 控制平面的响应速度。要识别故障并重新配置 Edge Gateway 可能需要最多 60 秒。

此方法模拟了基础架构故障，其中工作负载集群上的 **Ingress Gateway** 失败。

### 缩放上游服务

在每个工作负载集群上，**Gateway** 资源将流量转发到命名的上游服务，例如 `bookinfo/productpage.bookinfo.svc.cluster.local`。Tetrate 平台不会明确检查上游服务是否存在和运行，因此如果服务失败，平台将继续将流量引导到工作负载集群。

然而，作为 Edge Gateway 运行的 Envoy 代理会验证响应代码，并在可能的情况下重试请求，如果收到故障响应。在这种情况下，你会观察到针对失败的工作负载集群的请求生成 **503 UH no_healthy_upstream** 或类似的错误，然后 Envoy 会重试该请求以针对其他集群。Envoy 会在发送请求到失败的集群时进行退避，但会偶尔尝试以检测其恢复情况。

你可以通过以下方式调查故障行为，方法如下：

 * 通过将工作负载集群上游服务缩放为 0 个副本来引发服务故障：`kubectl scale deployment -n bookinfo productpage-v1 --replicas=0`
 * 通过将其缩放为 1 个副本来恢复服务

这种方法模拟了工作负载集群上的上游服务发生操作性故障的情况。

{{<callout note "内部服务故障转移">}}
此外，你还可以使用 **东西向网关** 来管理集群内部服务的故障转移。
{{</callout>}}


## 我们取得了什么成就？

我们观察了 Tetrate 平台在各种场景中检测故障并进行恢复的行为，这些场景包括 **工作负载集群** 或其托管的服务发生故障的情况。接下来，我们将考虑如何扩展 **Edge Gateways** 并处理一个或多个 **Edge 集群 / Edge Gateways** 的故障。