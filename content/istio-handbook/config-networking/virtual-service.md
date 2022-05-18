---
weight: 20
title: VirtualService
date: '2022-05-18T00:00:00+08:00'
type: book
---

`VirtualService` 主要配置流量路由。以下是在流量路由背景下定义的几个有用的术语。

- `Service` 是与服务注册表（service registry）中的唯一名称绑定的应用行为单元。服务由多个网络端点（endpoint）组成，这些端点由运行在 pod、容器、虚拟机等的工作负载实例实现。
- 服务版本，又称子集（subset）：在持续部署方案中，对于一个给定的服务，可能有不同的实例子集，运行应用程序二进制的不同变体。这些变体不一定是不同的 API 版本。它们可能是同一服务的迭代变化，部署在不同的环境（prod、staging、dev 等）。发生这种情况的常见场景包括 A/B 测试、金丝雀发布等。一个特定版本的选择可以根据各种标准（header、URL 等）和 / 或分配给每个版本的权重来决定。每个服务都有一个由其所有实例组成的默认版本。
- 源（source）：下游客户端调用服务。
- Host：客户端在尝试连接到服务时使用的地址。
- 访问模型（access model）：应用程序只针对目标服务（host），而不了解各个服务版本（子集）。版本的实际选择是由代理/sidecar 决定的，使应用程序代码脱离依赖服务。
- `VirtualService` 定义了一套当目标服务（host）被寻址时应用的流量路由规则。每个路由规则定义了特定协议流量的匹配标准。如果流量被匹配，那么它将被发送到注册表中定义的指定目标服务（或它的子集/版本）。

流量的来源也可以在路由规则中进行匹配。这允许为特定的客户环境定制路由。

## 示例

以下是 Kubernetes 上的例子，默认情况下，所有的 HTTP 流量都会被路由到标签为 `version: v1` 的 reviews 服务的 pod 上。此外，路径以 `/wpcatalog/` 或 `/consumercatalog/` 开头的 HTTP 请求将被重写为 `/newcatalog`，并被发送到标签为 `version: v2` 的 pod 上。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
spec:
  hosts:
  - reviews.prod.svc.cluster.local
  http:
  - name: "reviews-v2-routes"
    match:
    - uri:
        prefix: "/wpcatalog"
    - uri:
        prefix: "/consumercatalog"
    rewrite:
      uri: "/newcatalog"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v2
  - name: "reviews-v1-route"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1
```

途径目的地的子集/版本是通过对命名的服务子集的引用来识别的，这个子集必须在相应的 `DestinationRule` 中声明。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews-destination
spec:
  host: reviews.prod.svc.cluster.local
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

## 配置项

下图是 VirtualService 资源的配置拓扑图。

{{< figure src="../../images/virtualservice.png" alt="VirtualService"  caption="VirtualService 资源配置拓扑图" width="50%">}}

VirtualService 资源的顶级配置项如下：

- `hosts`：字符串数组格式。配置流量被发送到的目标主机。可以是一个带有通配符前缀的 DNS 名称或 IP 地址。根据平台的不同，也可以使用短名称来代替 FQDN（即名称中没有点）。在这种情况下，主机的 FQDN 将根据底层平台衍生出来。单个 VirtualService 可以用来描述相应主机的所有流量属性，包括多个 HTTP 和 TCP 端口的属性。另外，可以使用一个以上的 VirtualService 来定义主机的流量属性，但要注意一些问题。详情请参考[《流量管理最佳实践》](https://istio.io/latest/docs/ops/best-practices/traffic-management/)。

  Kubernetes 用户的注意事项。当使用短名称时（例如 `reviews` 而不是 `reviews.default.svc.cluster.local`），**Istio 将根据规则的命名空间而不是服务来解释短名称**。在 `default` 命名空间中包含主机 `reviews` 的规则将被解释为 `reviews.default.svc.cluster.local`，而不考虑与 `reviews` 服务相关的实际命名空间。为了避免潜在的错误配置，建议总是使用完全限定名而不是短名称。

  `hosts` 字段同时适用于 HTTP 和 TCP 服务。网格内的服务，即那些在服务注册表中发现的服务，必须始终使用它们的字母数字名称来引用。只允许通过网关定义的服务使用 IP 地址来引用。

  注意：对于委托的 VirtualService，必须是空的。

- `gateways`：字符串数组格式。配置应用路由的网关和 sidecar 的名称。其他命名空间中的 Gateway 可以通过 `<Gateway命名空间>/<Gateway名称>` 来引用；指定一个没有命名空间修饰词的 Gateway 默认与 VirtualService 位于同一命名空间。单个 VirtualService 用于网格内的 sidecar，也用于一个或多个网关。这个字段施加的选择条件可以使用协议特定路由的匹配条件中的源字段来覆盖。`mesh` 这个保留词被用来暗示网格中的所有 sidecar。当这个字段被省略时，将使用默认网关（`mesh`），这将把规则应用于网格中的所有 sidecar。如果提供了一个网关名称的列表，规则将只应用于网关。要将规则同时应用于网关和 sidecar，请指定 `mesh` 作为 Gateway 名称。

- `http`：HTTP 流量的路由规则的有序列表。HTTP 路由将应用于名为 `http-`/`http2-`/`grpc-*` 的平台服务端口、具有 HTTP/HTTP2/GRPC/TLS 终止的 HTTPS 协议的网关端口以及使用 HTTP/HTTP2/GRPC 协议的 ServiceEntry 端口。请注意该配置是有顺序的，请求第一个匹配的规则将被应用。

- `tls`：一个有序的路由规则列表，用于非终止的 TLS 和 HTTPS 流量。路由通常是使用 ClientHello 消息提出的 SNI 值来执行的。TLS 路由将被应用于平台服务端口 `https-`、`tls-`，使用 HTTPS/TLS 协议的未终止网关端口（即具有 `passthough` TLS 模式）和使用 HTTPS/TLS 协议的 ServiceEntry 端口。匹配传入请求的第一条规则被使用。注意：没有相关 VirtualService 的 `https-` 或 `tls-` 端口流量将被视为不透明的 TCP 流量。

- `tcp`：一个不透明的 TCP 流量的路由规则的有序列表。TCP 路由将被应用于任何不是 HTTP 或 TLS 端口。匹配传入请求的第一个规则被使用。

- `exportTo`：`VirtualService` 被导出的命名空间的列表。导出的 VirtualService 可以被定义在其它命名空间中的 sidecar 和 Gateway 使用。该功能为服务所有者和网格管理员提供了一种机制，以控制 VirtualService 在命名空间边界的可见性。

  如果没有指定命名空间，那么默认情况下，VirtualService 会被输出到所有命名空间。

  值 `.` 是保留的，它定义了导出到 VirtualService 声明的同一命名空间。同样，值 `*` 也是保留的，它定义了导出到所有命名空间。

## 完整示例

下面是一个相对完整的 VirtualService 配置的示例，其中包含了所有基本配置，对应的解释请见注释。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews-route
  namespace: bookinfo
spec:
  hosts:
  - reviews.prod.svc.cluster.local #目标主机
  gateways:
  - my-gateway #应用路由的网关和 sidecar 的名称
  http: #HTTP 路由规则
  - name: "reviews-v2-routes"
    match:
    - uri:
        prefix: "/wpcatalog"
    rewrite:
      uri: "/newcatalog"
    route:
    - destination:
        host: reviews.prod.svc.cluster.local
        subset: v1 #该子集是在 DestinationRule 中设置的
  tls: #关于 TLS 的设置
    mode: MUTUAL #一共有四种模式，DISABLE：关闭 TLS 连接；SIMPLE：发起一个与上游端点的 TLS 连接；MUTUAL：手动配置证书，通过出示客户端证书进行认证，使用双向的 TLS 确保与上游的连接；ISTIO_MUTUAL：该模式使用 Istio 自动生成的证书进行 mTLS 认证。
    clientCertificate: /etc/certs/myclientcert.pem
    privateKey: /etc/certs/client_private_key.pem
    caCertificates: /etc/certs/rootcacerts.pem
  exportTo: #指定 VirtualService 的可见性
    - "*" #*表示对所有命名空间可见，此为默认值；"."表示仅对当前命名空间可见
```

关于 VirtualService 配置的详细用法请参考 [Istio 官方文档](https://istio.io/latest/docs/reference/config/networking/virtual-service/)。

## 参考

- [Virtual Service - istio.io](https://istio.io/latest/docs/reference/config/networking/virtual-service/)