---
weight: 30
title: mTLS
date: '2022-05-18T00:00:00+08:00'
type: book
---

服务中的工作负载之间的通信是通过 Envoy 代理进行的。当一个工作负载使用 mTLS 向另一个工作负载发送请求时，Istio 会将流量重新路由到 sidecar 代理（Envoy）。

然后，sidecar Envoy 开始与服务器端的 Envoy 进行 mTLS 握手。在握手过程中，调用者会进行安全命名检查，以验证服务器证书中的服务账户是否被授权运行目标服务。一旦 mTLS 连接建立，Istio 就会将请求从客户端的 Envoy 代理转发到服务器端的 Envoy 代理。在服务器端的授权后，sidecar 将流量转发到工作负载。

我们可以在服务的目标规则中改变 mTLS 行为。支持的 TLS 模式有：`DISABLE`（无 TLS 连接）、`SIMPLE`（向上游端点发起 TLS 连接）、`MUTUAL`（通过出示客户端证书进行认证来使用 mTLS）和 `ISTIO_MUTUAL`（与 `MUTUAL` 类似，但使用 Istio 自动生成的证书进行 mTLS）。

## 什么是 mTLS？

在一个典型的 Kubernetes 集群中，加密的流量进入集群，经过一个负载均衡器终止 TLS 连接，从而产生解密的流量。然后，解密的流量被发送到集群内的相关服务。由于集群内的流量通常被认为是安全的，对于许多用例，这是一个可以接受的方法。

但对于某些用例，如处理个人身份信息（PII），可能需要额外的保护。在这些情况下，我们希望确保 **所有的** 网络流量，甚至同一集群内的流量，都是加密的。这为防止窥探（读取传输中的数据）和欺骗（伪造数据来源）攻击提供了额外保障。这可以帮助减轻系统中其他缺陷的影响。

如果手动实现这个完整的数据传输加密系统的话，需要对集群中的每个应用程序进行大规模改造。你需要告诉所有的应用程序终止自己的 TLS 连接，为所有的应用程序颁发证书，并为所有的应用程序添加一个新的证书颁发机构。

Istio 的 mTLS 在应用程序之外处理这个问题。它安装了一个 sidecar，通过 localhost 连接与你的应用程序进行通信，绕过了暴露的网络流量。它使用复杂的端口转发规则（通过 IPTables）来重定向进出 Pod 的流量，使其通过 sidecar。代理中的 Envoy sidecar 处理所有获取 TLS 证书、刷新密钥、终止等逻辑。

Istio 的这种工作方式虽然可以让你避免修改应用程序，但是当它可以工作时，能够工作得很好。而当它失败时，它可能是灾难性的，而且还难以调试。Istio 的 mTLS 值得一提的三个具体要点。

- 在严格模式（Strict Mode）下，也就是我们要做的，数据平面 Envoy 会拒绝任何传入的明文通信。

- 通常情况下，如果你对一个不存在的主机进行 HTTP 连接，你会得到一个失败的连接错误。你肯定 **不会** 得到一个 HTTP 响应。然而，在 Istio 中，你将 **总是** 成功地发出 HTTP 连接，因为你的连接是给 Envoy 本身的。如果 Envoy 代理不能建立连接，它将像大多数代理一样，返回一个带有 503 错误信息的 HTTP 响应体。
- Envoy 代理对一些协议有特殊处理。最重要的是，如果你做一个纯文本的 HTTP 外发连接，Envoy 代理有复杂的能力来解析外发请求，了解各种头文件的细节，并做智能路由。

## 允许模式

允许模式（Permissive Mode）是一个特殊的选项，它允许一个服务同时接受纯文本流量和 mTLS 流量。这个功能的目的是为了改善 mTLS 的用户体验。

默认情况下，Istio 使用允许模式配置目标工作负载。Istio 跟踪使用 Istio 代理的工作负载，并自动向其发送 mTLS 流量。如果工作负载没有代理，Istio 将发送纯文本流量。

当使用允许模式时，服务器接受纯文本流量和 mTLS 流量，不会破坏任何东西。允许模式给了我们时间来安装和配置 sidecar，以逐步发送 mTLS 流量。

一旦所有的工作负载都安装了 sidecar，我们就可以切换到严格的 mTLS 模式。要做到这一点，我们可以创建一个 `PeerAuthentication` 资源。我们可以防止非双向 TLS 流量，并要求所有通信都使用 mTLS。

我们可以创建 `PeerAuthentication` 资源，首先在每个命名空间中分别执行严格模式。然后，我们可以在根命名空间（在我们的例子中是 `istio-system`）创建一个策略，在整个服务网格中执行该策略：

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
```

此外，我们还可以指定`selector`字段，将策略仅应用于网格中的特定工作负载。下面的例子对具有指定标签的工作负载启用`STRICT`模式：

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: my-namespace
spec:
  selector:
    matchLabels:
      app: customers
  mtls:
    mode: STRICT
```

## 参考

- [An Istio/mutual TLS debugging story -fpcomplete.com](https://fpcomplete.com/blog/istio-mtls-debugging-story/)