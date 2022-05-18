---
weight: 40
title: Subset 和 DestinationRule
date: '2022-05-18T00:00:00+08:00'
type: book
---

目的地指的是不同的子集（subset）或服务版本。通过子集，我们可以识别应用程序的不同变体。在我们的例子中，我们有两个子集，`v1` 和 `v2`，它们对应于我们 customer 服务的两个不同版本。每个子集都使用键/值对（标签）的组合来确定哪些 Pod 要包含在子集中。我们可以在一个名为 `DestinationRule` 的资源类型中声明子集。

下面是定义了两个子集的 DestinationRule 资源的样子。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

让我们看看我们可以在 DestinationRule 中设置的流量策略。

## DestinationRule 中的流量策略

通过 DestinationRule，我们可以定义设置，如负载均衡配置、连接池大小、局部异常检测等，在路由发生后应用于流量。我们可以在`trafficPolicy`字段下设置流量策略设置。以下是这些设置：

- 负载均衡器设置
- 连接池设置
- 局部异常点检测
- 客户端 TLS 设置
- 端口流量策略

### 负载均衡器设置

通过负载均衡器设置，我们可以控制目的地使用哪种负载均衡算法。下面是一个带有流量策略的 DestinationRule 的例子，它把目的地的负载均衡算法设置为 `round-robin`。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: customers-destination
spec:
  host: customers.default.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

我们还可以设置基于哈希的负载均衡，并根据 HTTP 头、cookies 或其他请求属性提供会话亲和性。下面是一个流量策略的片段，它设置了基于哈希的负载均衡，并使用一个叫做 `location` 的 cookie 来实现亲和力。

```yaml
trafficPolicy:
  loadBalancer:
    consistentHash:
      httpCookie:
        name: location
        ttl: 4s
```

### 连接池配置

这些设置可以在 TCP 和 HTTP 层面应用于上游服务的每个主机，我们可以用它们来控制连接量。

下面是一个片段，显示了我们如何设置对服务的并发请求的限制。

```yaml
spec:
  host: myredissrv.prod.svc.cluster.local
  trafficPolicy:
    connectionPool:
      http:
        http2MaxRequests: 50
```

### 异常点检测

异常点检测是一个断路器的实现，它跟踪上游服务中每个主机（Pod）的状态。如果一个主机开始返回 5xx HTTP 错误，它就会在预定的时间内被从负载均衡池中弹出。对于 TCP 服务，Envoy 将连接超时或失败计算为错误。

下面是一个例子，它设置了 500 个并发的 HTTP2 请求（`http2MaxRequests`）的限制，每个连接不超过 10 个请求（`maxRequestsPerConnection`）到该服务。每 5 分钟扫描一次上游主机（Pod）（`interval`），如果其中任何一个主机连续失败 10 次（`contracticalErrors`），Envoy 会将其弹出 10 分钟（`baseEjectionTime`）。

```yaml
trafficPolicy:
  connectionPool:
    http:
      http2MaxRequests: 500
      maxRequestsPerConnection: 10
  outlierDetection:
    consecutiveErrors: 10
    interval: 5m
    baseEjectionTime: 10m
```

### 客户端 TLS 设置

包含任何与上游服务连接的 TLS 相关设置。下面是一个使用提供的证书配置 mTLS 的例子。

```yaml
trafficPolicy:
  tls:
    mode: MUTUAL
    clientCertificate: /etc/certs/cert.pem
    privateKey: /etc/certs/key.pem
    caCertificates: /etc/certs/ca.pem
```

其他支持的 TLS 模式有 `DISABLE`（没有 TLS 连接），`SIMPLE`（在上游端点发起 TLS 连接），以及 `ISTIO_MUTUAL`（与 `MUTUAL` 类似，使用 Istio 的 mTLS 证书）。

### 端口流量策略

使用 `portLevelSettings` 字段，我们可以将流量策略应用于单个端口。比如说：

```yaml
trafficPolicy:
  portLevelSettings:
  - port:
      number: 80
    loadBalancer:
      simple: LEAST_CONN
  - port:
      number: 8000
    loadBalancer:
      simple: ROUND_ROBIN
```
