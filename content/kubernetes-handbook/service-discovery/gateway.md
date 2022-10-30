---
weight: 42
title: Gateway API
date: '2022-05-21T00:00:00+08:00'
type: book
---

除了直接使用 Service 和 Ingress 之外，Kubernetes 社区还发起了 [Gateway API 项目](https://github.com/kubernetes-sigs/gateway-api)，它可以帮助我们将 Kubernetes 中的服务暴露到集群外。

{{<callout note "Gateway API 与 Ingress 有什么不同？">}}

Ingress 的主要目标是用简单的、声明性的语法来暴露 HTTP 应用。Gateway API 暴露了一个更通用的代理 API，可以用于更多的协议，而不仅仅是 HTTP，并为更多的基础设施组件建模，为集群运营提供更好的部署和管理选项。

{{</callout>}}

Gateway API 是一个由 [SIG-NETWORK](https://github.com/kubernetes/community/tree/master/sig-network) 管理的开源项目。该项目的目标是在 Kubernetes 生态系统中发展服务网络 API。Gateway API 提供了暴露 Kubernetes 应用的资源——`GatewayClass`、`Gateway`、`HTTPRoute`、`TCPRoute` 等。

该 API 在 Istio 中也被应用，用于将网格内的服务暴露到集群外。

## 目标

Gateway API 旨在通过提供表现性的、可扩展的、面向角色的接口来改善服务网络，这些接口由许多厂商实现，并得到了业界的广泛支持。

Gateway API 是一个 API 资源的集合 —— `GatewayClass`、`Gateway`、`HTTPRoute`、`TCPRoute` 等。使用这些资源共同为各种网络用例建模。

下图中展示的是 Kubernetes 集群中四层和七层的网络配置。从图中可以看到通过将这些资源对象分离，可以实现配置上的解耦，由不同角色的人员来管理，而这也是 Gateway API 的相较于 Ingress 的一大特色。

![Kubernetes Gateway API 简介](../../images/gateway-api.svg "Kubernetes Gateway API 简介")

## Gateway 相较于 Ingress 做了哪些改进？

以下是 Gateway API 对 Ingress 的改进点。

**更具表现力**

Gateway 表达了更多的核心功能，比如基于头的匹配、流量加权和其他功能，而这些功能在 Ingress 中只能通过自定义方式实现。

**更具扩展性**

Gateway API 允许在 API 的各个层次上链接自定义资源。这就允许在 API 结构的适当位置进行更精细的定制。

**面向角色**

它们被分离成不同的 API 资源，这些资源映射到 Kubernetes 上运行应用程序的常见角色。

**通用性**

这不是一种改进，而是应该保持不变。正如 Ingress 是一个具有众多实现的通用规范一样，Gateway API 被设计成一个由许多实现支持的可移植规范。

**共享网关**

它们允许独立的路由资源绑定到同一个网关，从而实现负载均衡器和 VIP 的共享。这允许团队安全地共享基础设施，而不需要直接协调。

**类型化后端引用**

通过类型化后端引用，Routes 可以引用 Kubernetes 服务，也可以引用任何一种被设计为 Gateway 后端的 Kubernetes 资源。

**跨命名空间引用**

跨越不同 Namespaces 的路由可以绑定到网关。这样，尽管对工作负载进行了命名空间划分，但仍可共享网络基础设施。

**类**

`GatewayClasses` 将负载均衡实现的类型形式化。这些类使用户可以很容易和明确地了解资源模型本身有什么样的能力。

在了解了 Gateway API 的目的后，接下来我们再看下它的资源模型、请求流程、TLS 配置及扩展点等。

## 角色划分

Gateway API 开发者为其使用场景定义四类角色：

- 基础设施提供方：如 AWS、GKE 等
- 集群运维：管理整个集群的计算、存储、网络、安全等
- 应用程序开发者：为自己开发的应用负责，管理应用的健壮性
- 应用管理员：不是所有的公司都有，通常在一些复杂系统中会有专门的应用管理员

Gateway API 通过 Kubernetes 服务网络的面向角色的设计在分布式灵活性和集中控制之间取得了平衡。使得许多不同的非协调团队可以使用共享网络基础设施（硬件负载均衡器、云网络、集群托管代理等），所有团队都受集群运维设置的策略约束。下图展示了在进行 Gateway 管理时的角色划分。

![Gateway 管理中的角色划分（图片来自：https://gateway-api.sigs.k8s.io/）](../../images/gateway-roles.png)

集群运维人员创建从 [GatewayClass](https://gateway-api.sigs.k8s.io/api-types/gatewayclass) 派生的 [Gateway](https://gateway-api.sigs.k8s.io/api-types/gateway) 资源。此 Gateway 部署或配置它所代表的底层网络资源。通过 Gateway 和 Route 之间的[路由附加进程](https://gateway-api.sigs.k8s.io/concepts/api-overview#attaching-routes-to-gateways) ，集群运维人员和特定团队必须就可以附加到此 Gateway 并通过它公开其应用程序的内容达成一致。集群运维人员可以在网关上实施  [TLS](https://gateway-api.sigs.k8s.io/guides/tls#downstream-tls) 集中式策略。同时，Store 和 Site 团队[在他们自己的 Namespaces 中](https://gateway-api.sigs.k8s.io/guides/multiple-ns)运行，但是将他们的 Routes 附加到同一个共享 Gateway，允许他们独立控制自己的[路由逻辑](https://gateway-api.sigs.k8s.io/guides/http-routing)。这种关注点分离允许 Store 队管理自己的[流量拆分部署](https://gateway-api.sigs.k8s.io/guides/traffic-splitting)，同时将集中策略和控制权留给集群运维人员。

这种灵活性技能保持 API 的标准和可移植性，还使其可以适应截然不同的组织模型和实现。

## 资源模型

注意：资源最初将作为 CRD 存在于 `networking.x-k8s.io` API 组中。未限定的资源名称将隐含在该 API 组中。

Gateway API 的资源模型中，主要有三种类型的对象：

- `GatewayClass`：定义了一组具有共同配置和行为的网关。
- `Gateway`：请求一个点，在这个点上，流量可以被翻译到集群内的服务。
- `Route`：描述了通过 Gateway 而来的流量如何映射到服务。

### GatewayClass

`GatewayClass` 定义了一组共享共同配置和行为的 Gateway，每个 `GatewayClass` 由一个控制器处理，但控制器可以处理多个 `GatewayClass`。

`GatewayClass` 是一个集群范围的资源。必须至少定义一个 `GatewayClass`，`Gateway` 才能够生效。实现 Gateway API 的控制器通过关联的 `GatewayClass` 资源来实现，用户可以在自己的 `Gateway` 中引用该资源。

这类似于 `Ingress` 的 `IngressClass` 和 `PersistentVolumes` 的 [`StorageClass`](https://kubernetes.io/docs/concepts/storage/storage-classes/)。在 `Ingress` v1beta1 中，最接近 `GatewayClass` 的是 `ingress-class` 注解，而在 IngressV1 中，最接近的类似物是 `IngressClass` 对象。

### Gateway

`Gateway` 描述了如何将流量翻译到集群内的服务。它定义了一个将流量从不了解 Kubernetes 的地方翻译到了解 Kubernetes 的地方的方法。例如，由云负载均衡器、集群内代理或外部硬件负载均衡器发送到 Kubernetes 服务的流量。虽然许多用例的客户端流量源自集群的 "外部"，但这并不是必需的。

`Gateway` 定义了对实现 `GatewayClass` 配置和行为合同的特定负载均衡器配置的请求。该资源可以由运维人员直接创建，也可以由处理 `GatewayClass` 的控制器创建。

由于 `Gateway` 规范捕获了用户意图，它可能不包含规范中所有属性的完整规范。例如，用户可以省略地址、端口、TLS 设置等字段。这使得管理 `GatewayClass` 的控制器可以为用户提供这些设置，从而使规范更加可移植。这种行为将通过 `GatewayClass` 状态对象来明确。

一个 `Gateway` 可以包含一个或多个 `Route` 引用，这些 `Route` 引用的作用是将一个子集的流量引导到一个特定的服务上。

### Route

`Route` 对象定义了特定协议的规则，用于将请求从 `Gateway` 映射到 Kubernetes 服务。

从 v1alpha2 开始，Gateway API 中包含四种 `Route` 资源类型。对于其他协议，鼓励使用特定于实现的自定义路由类型。未来可能会向 API 添加新的路由类型。

{{<callout note "注意">}}

目前除了 `HTTPRoute` 是 Gateway API 正式支持的，其他的路由类型还在实验中，详见[版本文档](https://gateway-api.sigs.k8s.io/concepts/versioning/)。

{{</callout>}}

#### HTTPRoute

`HTTPRoute` 用于多路复用 HTTP 或终止的 HTTPS 连接。它适用于检查 HTTP 流并使用 HTTP 请求数据进行路由或修改的情况，例如使用 HTTP Header 进行路由或在运行中修改它们。

#### TLSRoute

`TLSRoute` 用于多路复用 TLS 连接，通过 SNI 进行区分。它适用于使用 SNI 作为主要路由方法的地方，并且对 HTTP 等高级协议的属性不感兴趣。连接的字节流被代理，无需对后端进行任何检查。

#### TCPRoute 和 UDPRoute

`TCPRoute`（和 `UDPRoute`）旨在用于将一个或多个端口映射到单个后端。在这种情况下，没有可用于在同一端口上选择不同后端的鉴别器（Discriminator），因此每个 `TCPRoute` 确实需要监听器上的不同端口（通常，无论如何）。你可以终止 TLS，在这种情况下，未加密的字节流被传递到后端。你可以选择不终止 TLS，在这种情况下，加密的字节流被传递到后端。

#### GRCPRoute

`GRPCRoute` 用于惯用地路由 gRPC 流量。支持 `GRPCRoute` 的网关需要支持 HTTP/2，而无需从 HTTP/1 进行初始升级，因此可以保证 gRPC 流量正常流动。

#### Route 类型列表

下面的「路由鉴别器」一栏是指可以使用哪些信息来允许多个 Routes 共享 Listener 上的端口。

| 对象        | OSI 层                         | 路由鉴别器            | TLS 支持   | 目的                                           |
| :---------- | :----------------------------- | :-------------------- | :--------- | :--------------------------------------------- |
| `HTTPRoute` | 第 7 层                        | HTTP 协议中的任何内容 | 仅终止     | HTTP 和 HTTPS 路由                             |
| `TLSRoute`  | 第 4 层和第 7 层之间的某个位置 | SNI 或其他 TLS 属性   | 直通或终止 | TLS 协议的路由，包括不需要检查 HTTP 流的 HTTPS |
| `TCPRoute`  | 第 4 层                        | 目的端口              | 直通或终止 | 允许将 TCP 流从 Listener 转发到 Backends       |
| `UDPRoute`  | 第 4 层                        | 目的端口              | 没有任何   | 允许将 UDP 流从监听器转发到后端                |
| `GRPCRoute` | 第 7 层                        | gRPC 协议中的任何内容 | 仅终止     | 基于 HTTP/2 和 HTTP/2 明文的 gRPC 路由         |

请注意，通过 `HTTPRoute` 和 `TCPRoute` 路由的流量可以在网关和后端之间进行加密（通常称为重新加密）。无法使用现有的 Gateway API 资源对其进行配置，但实现可以为此提供自定义配置，直到 Gateway API 定义了标准化方法。

### 将路由添加到网关

将 Route 附加到 Gateway 表示在 Gateway 上应用的配置，用于配置底层负载均衡器或代理。Route 如何以及哪些 Route 附加到 Gateway 由资源本身控制。Route 和 Gateway 资源具有内置控件以允许或限制它们的连接方式。与 Kubernetes RBAC 一起，这些允许组织实施有关如何公开  Route 以及在公开在哪些 Gateway 上的策略。

如何将 Route 附加到网关以实现不同的组织策略和责任范围有很大的灵活性。下面是 Gateway 和 Route 可以具有的不同关系：

- **一对一**：Gateway 和 Route 可以由单个所有者部署和使用，具有一对一的关系。
- **一对多**： Gateway 可以绑定许多 Route，这些 Route 由来自不同命名空间的不同团队拥有。
- **多对一**：Route 也可以绑定到多个 Gateway，允许单个 Route 同时控制跨不同 IP、负载均衡器或网络的应用程序公开。

### 路由绑定

当 `Route` 绑定到 `Gateway` 时，代表应用在 `Gateway` 上的配置，配置了底层的负载均衡器或代理。哪些 `Route` 如何绑定到 `Gateway` 是由资源本身控制的。`Route` 和 `Gateway` 资源具有内置的控制，以允许或限制它们之间如何相互选择。这对于强制执行组织政策以确定 `Route` 如何暴露以及在哪些 `Gateway` 上暴露非常有用。看下下面的例子。

一个 Kubernetes 集群管理员在 `Infra` 命名空间中部署了一个名为 `shared-gw` 的 `Gateway`，供不同的应用团队使用，以便将其应用暴露在集群之外。团队 A 和团队 B（分别在命名空间 "A" 和 "B" 中）将他们的 `Route` 绑定到这个 `Gateway`。它们互不相识，只要它们的 `Route` 规则互不冲突，就可以继续隔离运行。团队 C 有特殊的网络需求（可能是性能、安全或关键性），他们需要一个专门的 `Gateway` 来代理他们的应用到集群外。团队 C 在 "C" 命名空间中部署了自己的 `Gateway` `specialive-gw`，该 Gateway 只能由 "C" 命名空间中的应用使用。

不同命名空间及 `Gateway` 与 `Route` 的绑定关系如下图所示。

![路由绑定示意图](../../images/gateway-api-route-binding.jpg "路由绑定示意图")

将路由附加到网关包括以下步骤：

1. Route 需要在其 `parentRefs` 字段中引用 Gateway 的条目；
2. Gateway 上的至少一个监听器需要允许其附着。

## 引用网关

Route 可以通过在`parentRef`. 路由可以使用以下字段进一步选择网关下的监听器子集`parentRef`：

Route 可以通过在 `parentRef` 中指定命名空间（如果 Route 和 Gateway 在同一个名称空间中则该配置是可选的）和 Gateway 的名称来引用 Gateway。Route 可以使用 `parentRef` 中的以下字段进一步选择 Gateway 下的监听器子集：

1. **SectionName**：当设置了 `sectionName` 时，Route 选择具有指定名称的监听器；
2. **Port**：当设置了 `port` 时，Route 会选择所有指定的监听端口且协议与此类 Route 兼容的监听器。

当设置了多个 `parentRef` 字段时，Route 选择满足这些字段中指定的所有条件的监听器。例如，当 `sectionName` 和 `port` 两者都设置时，Route 选择具有指定名称的监听器并在指定端口上监听。

### 限制路由附加

每个 Gateway 监听器都可以通过以下机制限制其可以附加哪些路由：

1. **Hostname**：设置监听器上的 `hostname` 字段时，指定`hostnames` 字段的附加路由必须至少有一个重叠值。
2. **Namespace**：监听器上的 `allowedRoutes.namespaces` 字段可用于限制可以附加路由的位置。该 `namespaces.from` 字段支持以下值：
   - `SameNamespace` 是默认选项。只有与该网关相同的命名空间中的路由才会被选择。
   - `All` 将选择来自所有命名空间的 `Route`。
   - `Selector` 意味着该网关将选择由 Namespace 标签选择器选择的 Namespace 子集的 Route。当使用 Selector 时，那么 `listeners.route.namespaces.selector` 字段可用于指定标签选择器。`All` 或 `SameNamespace` 不支持该字段。
3. **Kind**：监听器上的 `allowedRoutes.kinds` 字段可用于限制可能附加的路由种类。

如果未指定上述任何一项，网关监听器将信任从支持监听器协议的同一命名空间附加的路由。

### 更多 Gateway - Route 附加示例

以下 `gateway-api-example-ns1` 命名空间中的 `my-route` Route 想要附加到 `foo-gateway` 中， 不会附加到任何其他 Gateway。请注意， `foo-gateway` 它位于不同的命名空间中。`foo-gateway` 必须允许来自 `gateway-api-example-ns2` 命名空间中的 HTTPRoutes 附加。

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: my-route
  namespace: gateway-api-example-ns2
spec:
  parentRefs:
  - kind: Gateway
    name: foo-gateway
    namespace: gateway-api-example-ns1
  rules:
  - backendRefs:
    - name: foo-svc
      port: 8080
```

`foo-gateway` 允许 `my-route` HTTPRoute 附加。

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: foo-gateway
  namespace: gateway-api-example-ns1
spec:
  gatewayClassName: foo-lb
  listeners:
  - name: prod-web
    port: 80
    protocol: HTTP
    allowedRoutes:
      kinds: 
        - kind: HTTPRoute
      namespaces:
        from: Selector
        selector:
          matchLabels:
            # 该 label 在 Kubernetes 1.22 中自动添加到所有命名空间中
            kubernetes.io/metadata.name: gateway-api-example-ns2
```

对于一个更宽松的示例，下面的网关将允许所有 HTTPRoute 资源从带有 `expose-apps: true` 标签的命名空间附加。

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: gateway-api-example-ns1
spec:
  gatewayClassName: foo-lb
  listeners:
  - name: prod-web
    port: 80
    protocol: HTTP    
    allowedRoutes:
      kinds: 
        - kind: HTTPRoute
      namespaces:
        from: Selector
        selector:
          matchLabels:
            expose-apps: "true"
```

### 组合类型

`GatewayClass`、Gateway、`xRoute` 和 `Service` 的组合将定义一个可实现的负载均衡器。下图说明了不同资源之间的关系。

![Gateway API 流程图](../../images/gateway-api-request-flow.png "Gateway API 流程图")

## 请求流程

使用反向代理实现的网关的一个典型的客户端 / 网关 API 请求流程是：

1. 客户端向 `http://foo.example.com` 发出请求。
2. DNS 将该名称解析为网关地址。
3. 反向代理在 `Listener` 上接收请求，并使用 `Host` 头 来匹配 `HTTPRoute`。
4. 可选地，反向代理可以根据 `HTTPRoute` 的匹配规则执行请求头和 / 或路径匹配。
5. 可选地，反向代理可以根据 `HTTPRoute` 的过滤规则修改请求，即添加 / 删除头。
6. 最后，反向代理可以根据 `HTTPRoute` 的 `forwardTo` 规则，将请求转发到集群中的一个或多个对象，即 `Service`。

## TLS 配置

TLS 配置在 `Gateway` 监听器上，可以跨命名空间引用。

## 扩展点

API 中提供了一些扩展点，以灵活处理大量通用 API 无法处理的用例。

以下是 API 中扩展点的摘要。

- `BackendRefs`：此扩展点应用于将流量转发到核心 Kubernetes 服务资源以外的网络端点。例如 S3 存储桶、Lambda 函数、文件服务器等。
- `HTTPRouteFilter`：`HTTPRoute` 中的这种 API 类型提供了一种挂钩 HTTP 请求的请求 / 响应生命周期的方法。
- **自定义路由**：如果上述扩展点都不能满足用例的需要，实施者可以选择为 API 当前不支持的协议创建自定义路由资源。自定义路由类型需要共享与核心路由类型相同的字段。这些包含在 `CommonRouteSpec` 和 `RouteStatus` 中。

## 参考

- [kuberentes-sigs/gateway-api - github.com](https://github.com/kubernetes-sigs/gateway-api)
