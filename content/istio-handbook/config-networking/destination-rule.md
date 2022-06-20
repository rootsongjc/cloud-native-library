---
weight: 30
title: DestinationRule
date: '2022-05-18T00:00:00+08:00'
type: book
---

`DestinationRule` 定义了在路由发生后适用于服务流量的策略。这些规则指定了负载均衡的配置、来自 sidecar 的连接池大小，以及用于检测和驱逐负载均衡池中不健康主机的异常检测设置。

## 示例

例如，ratings 服务的一个简单的负载均衡策略看起来如下。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
```

可以通过定义一个 `subset` 并覆盖在服务级来配置特定版本的策略。下面的规则对前往由带有标签（`version:v3`）的端点（如 pod）组成的名为 `testversion` 的子集的所有流量使用轮询负载均衡策略。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN
  subsets:
  - name: testversion
    labels:
      version: v3
    trafficPolicy:
      loadBalancer:
        simple: ROUND_ROBIN
```

**注意**：只有当路由规则明确地将流量发送到这个子集，为子集指定的策略才会生效。

流量策略也可以针对特定的端口进行定制。下面的规则对所有到 80 号端口的流量使用最少连接的负载均衡策略，而对 9080 号端口的流量使用轮流负载均衡设置。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings-port
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy: # 应用到所有端口
    portLevelSettings:
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_CONN
    - port:
        number: 9080
      loadBalancer:
        simple: ROUND_ROBIN
```

## 配置项

下图是 DestinationRule 资源的配置拓扑图。

{{< figure src="../../images/destinationrule.png" alt="DestinationRule"  caption="DestinationRule 资源配置拓扑图" width="50%">}}

DestinationRule 资源的顶级配置项如下：

- `host`：字符串类型。来自服务注册表的服务名称。服务名称从平台的服务注册表（例如，Kubernetes 服务、Consul 服务等）和 ServiceEntry 声明的主机中查找。为服务注册表中不存在的服务定义的规则将被忽略。

  Kubernetes 用户的注意事项。当使用短名称时（例如 `reviews` 而不是 `reviews.default.svc.cluster.local`），Istio 将根据规则的命名空间而不是服务来解释短名称。在 `default` 命名空间中包含主机 `reviews` 的规则将被解释为 `reviews.default.svc.cluster.local`，而不考虑与 reviews 服务相关的实际命名空间。为了避免潜在的错误配置，建议总是使用完全限定名而不是短名称。

  注意，主机字段适用于 HTTP 和 TCP 服务。

- `trafficPolicy`：要应用的流量策略（负载均衡策略、连接池大小、异常值检测）。

- `subsets`：一个或多个命名的集合，代表一个服务的单独版本。流量策略可以在子集级别被覆盖。

- `exportTo`：`DestinationRule` 被导出的命名空间的列表。DestinationRule 的解析是在命名空间级别中进行的。导出的 DestinationRule 被包含在其他命名空间的服务的解析层次中。该功能为服务所有者和网格管理员提供了一种机制，以控制 DestinationRule 在命名空间边界的可视性。

  如果没有指定命名空间，那么默认情况下，DestinationRule 会被输出到所有命名空间。

  值 `.` 是保留的，它定义了导出到 DestinationRule 声明的同一命名空间。同样，值 `*` 也是保留的，它定义了导出到所有命名空间。

下面是一些重要的配置项的使用说明。

## 示例配置

下面是一个相对完整的 DestinationRule 配置的示例，其中包含了所有基本配置，对应的解释请见注释。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
  namespace: bookinfo
spec:
  host: ratings.prod.svc.cluster.local #来自服务注册表的服务名称
  trafficPolicy: #要应用的流量策略，默认是应用与所有端口
    loadBalancer: #配置负载均衡算法
      simple: ROUND_ROBIN
    portLevelSettings: #对指定端口应用流量策略，可覆盖全局配置
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_CONN
  connectionPool: #配置上游服务的连接量，可以配置 TCP 和 HTTP
  	tcp: #同时适用于 TCP 和 HTTP 上游连接
      maxConnections: 100 #与上游服务的最大连接数
      connectTimeout: 30ms #TCP 连接的超时时间，默认为 10s
      tcpKeepalive: #如果有该配置，则在套接字上设置 SO_KEEPALIVE，以启用 TCP Keepalive。
        time: 7200s  #最后一次探测和第一次探测之间间隔的时间。默认是使用操作系统级别的配置（除非被覆盖，Linux默认为7200s，即2小时。）
        interval: 75s #探测发送间隔，默认是 75s
        probs: 9 # 最大探测次数，使用操作系统级别的默认值，Linux 系统的默认值是 9，如果超过该次数没有得到回复，则意味着连接断开了
    http: #针对 HTTP 连接池的配置
      http2MaxRequests: 1000 #最大请求数
      maxRequestsPerConnection: 10 #每个连接中的最大请求数，默认是 0，意味着没有限制
      maxRetries: 5 #在给定时间内，集群中的所有主机未完成的最大重试次数
  outlierDetection: #异常值检测，实际为一个断路器实现，跟踪上游服务中每个独立主机的状态。同时适用于 HTTP 和 TCP 服务。对于 HTTP 服务，持续返回 5xx 错误的 API 调用的主机将在预先定义的时间内从连接池中弹出。对于 TCP 服务，在测量连续错误指标时，对特定主机的连接超时或连接失败算作一个错误。
    consecutive5xxErrors: 7 #当达到 7 次 5xx 错误时，该主机将从上游连接中弹出。当通过不透明的 TCP 连接被访问时上游主机时，连接超时、错误/失败和请求失败事件都有资格成为5xx错误。该功能默认为5，但可以通过设置该值为0来禁用。
    interval: 5m #异常值检测的时间间隔，默认是为 10s
    baseEjectionTime: 15m #主机将保持弹出的时间，等于最小弹出持续时间和主机被弹出次数的乘积。这种技术允许系统自动增加不健康的上游服务器的弹出时间。默认为 30s。
  tls: #关于 TLS 的设置
    mode: MUTUAL #一共有四种模式，DISABLE：关闭 TLS 连接；SIMPLE：发起一个与上游端点的 TLS 连接；MUTUAL：手动配置证书，通过出示客户端证书进行认证，使用双向的 TLS 确保与上游的连接；ISTIO_MUTUAL：该模式使用 Istio 自动生成的证书进行 mTLS 认证。
    clientCertificate: /etc/certs/myclientcert.pem
    privateKey: /etc/certs/client_private_key.pem
    caCertificates: /etc/certs/rootcacerts.pem
  subsets: #服务版本
  - name: v1
    labels:
      version: v1 #所有具有该标签的 Pod 被划分为该子集
  exportTo: #指定DestinationRule 的可视性
    - "*" #*表示对所有命名空间可见，此为默认值；"."表示仅对当前命名空间可见
```

关于 DestinationRule 配置的详细用法请参考 [Istio 官方文档](https://istio.io/latest/docs/reference/config/networking/destination-rule/)。

## 参考

- [Destination Rule - istio.io](https://istio.io/latest/docs/reference/config/networking/destination-rule/)
