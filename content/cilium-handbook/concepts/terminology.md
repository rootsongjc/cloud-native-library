---
weight: 2
title: Cilium 术语说明
date: '2022-06-17T12:00:00+08:00'
type: book
---

## 标签 {#labels}

标签（Label）是一种通用的、灵活的和高度可扩展的方式，可以用来处理大量资源，因为我们可以用它来对事物任意分组和创建集合。每当需要描述、解决或选择某物时，它都是基于标签完成的：

- [端点](#endpoints) 被分配了从容器运行时、编排系统或其他来源派生的标签。
- [网络策略](../../policy/) 根据标签选择允许通信的 [端点对](#endpoints)，策略本身也由标签标识。

### 什么是标签？{#what-is-a-label}

标签是一对由 `key` 和 `value` 组成的字符串。可以将标签格式化为具有 `key=value` 的单个字符串。`key` 部分是强制性的，并且必须是唯一的。这通常是通过使用反向域名概念来实现的，例如 `io.cilium.mykey=myvalue`。`value` 部分是可选的，可以省略，例如 `io.cilium.mykey`.

键名通常应由字符集组成 `[a-z0-9-.]`。

当使用标签选择资源时，键和值都必须匹配，例如，当一个策略应该应用于所有带有标签 `my.corp.foo` 的端点时，标签 `my.corp.foo=bar` 不会与该选择器匹配。

### 标签来源 {#label-source}

标签可以来自各种来源。例如，[端点](#endpoint) 将通过本地容器运行时派生与容器关联的标签，以及与 Kubernetes 提供的 pod 关联的标签。由于这两个标签命名空间彼此不知道，这可能会导致标签键冲突。

为了解决这种潜在的冲突，Cilium 在导入标签时为所有标签键添加前缀 `source:` 以指示标签的来源，例如 `k8s:role=frontend`、`container:user=joe`、`k8s:role=backend`。这意味着当您使用 `docker run [...] -l foo=bar` 运行 Docker 容器时，标签 `container:foo=bar` 将出现在代表容器的 Cilium 端点上。类似地，以 `foo: bar` 标签启动的 Kubernetes pod 将由与标签关联的 Cilium 端点表示 。为每个潜在来源分配一个唯一名称。当前支持以下标签源：

- `container:` 对于从本地容器运行时派生的标签
- `k8s:` 对于从 Kubernetes 派生的标签
- `reserved:` 有关特殊保留标签，请参阅 [特殊标识](#reserved-labels)。
- `unspec:` 对于未指定来源的标签

当使用标签来识别其他资源时，可以包含源以将标签匹配限制为特定类型。如果未提供源，则标签源默认为 `any:`，将匹配所有标签，无论其来源如何。如果提供了来源，则选择和匹配标签的来源需要匹配。

## 端点 {#endpoints}

Cilium 通过分配 IP 地址使应用程序容器在网络上可用。多个应用容器可以共享同一个 IP 地址；此模型的一个典型示例是 Kubernetes Pod。所有共享公共地址的应用程序容器都在 Cilium 所指的端点中分组在一起。

分配单独的 IP 地址允许每个端点使用整个四层端口范围。这实质上允许在同一个集群节点上运行的多个应用程序容器都绑定到众所周知的端口，例如 `80` 不会引起任何冲突。

Cilium 的默认行为是为每个端点分配 IPv6 和 IPv4 地址。但是，可以将此行为配置为仅使用该 `--enable-ipv4=false` 选项分配 IPv6 地址。如果同时分配了 IPv6 和 IPv4 地址，则任一地址都可用于到达端点。相同的行为将适用于策略规则、负载均衡等。

### 身份识别 {#identification}

出于识别目的，Cilium 为集群节点上的所有端点分配一个内部端点 ID。端点 ID 在单个集群节点的上下文中是唯一的。

### 端点元数据 {#endpoint-metadata}

端点自动从与端点关联的应用程序容器中派生元数据。然后可以使用元数据来识别端点，以实现安全 / 策略、负载均衡和路由目的。

元数据的来源取决于使用的编排系统和容器运行时。当前支持以下元数据检索机制：

| 系统                 | 描述                            |
| -------------------- | ------------------------------- |
| Kubernetes           | Pod 标签（通过 Kubernetes API） |
| containerd（Docker） | 容器标签（通过 Docker API）     |

元数据以 [标签](#labels) 的形式附加到端点。

以下示例启动一个带有标签的容器，该标签 `app=benchmark` 随后与端点相关联。标签带有前缀， `container:` 表示标签是从容器运行时派生的。

```bash
$ docker run --net cilium -d -l app=benchmark tgraf/netperf
aaff7190f47d071325e7af06577f672beff64ccc91d2b53c42262635c063cf1c
$  cilium endpoint list
ENDPOINT   POLICY        IDENTITY   LABELS (source:key [=value])   IPv6                   IPv4            STATUS
           ENFORCEMENT
62006      Disabled      257        container:app=benchmark       f00d::a00:20f:0:f236   10.15.116.202   ready
```

一个端点可以有来自多个源的元数据。例如使用 containerd 作为容器运行时的 Kubernetes 集群。端点将派生 Kubernetes pod 标签（以`k8s:`源前缀为前缀）和容器标签（以`container:` 源前缀为前缀）。

## 身份 {#identity}

所有 [端点](#endpoints) 都分配了一个身份。身份用于端点之间的基本连接。在传统的网络术语中，这运行在三层。

身份由 [标签](#labels) 标识，并被赋予一个集群范围的唯一标识符。端点被分配与端点的 [安全相关标签](#security-relevant-labels) 匹配的身份，即共享同一组 [安全相关标签](#security-relevant-labels) 的所有端点将共享相同的身份。此概念允许将策略实施扩展到大量端点，因为随着应用程序的扩展，许多单独的端点通常会共享同一组安全 [标签](#labels)。

### 什么是身份？{#what-is-an-identity}

端点的身份是基于与派生到 [端点](#endpoint) 的 pod 或容器关联的 [标签](#labels) 派生的。当一个 pod 或容器启动时，Cilium 会根据容器运行时收到的事件创建一个 [端点](#endpoint) 来代表网络上的 pod 或容器。下一步，Cilium 将解析 [端点](#endpoint) 创建的身份。每当 Pod 或容器的 [标签](#labels) 发生变化时，都会重新确认身份并根据需要自动修改。

### 安全相关标签 {#security-relevant-labels}

在派生 [身份](#identity) 时，并非所有与容器或 pod 关联的 [标签](#labels) 都有意义。标签可用于存储元数据，例如容器启动时的时间戳。Cilium 需要知道哪些标签是有意义的，知道在推导身份时需要考虑哪些标签。为此，用户需要指定有意义标签的字符串前缀列表。标准行为是包含所有以 `id` 为前缀开头的标签， 例如，``id.service1``、`id.service2`、`id.groupA.service44`。启动代理时可以指定有意义的标签前缀列表。

### 特殊身份 {#special-identities}

Cilium 管理的所有端点都将被分配一个身份。为了允许与不由 Cilium 管理的网络端点进行通信，存在特殊的身份来表示它们。特殊保留标识以 `reserved:` 字符串为前缀。

| 身份                      | 数字 ID | 描述                                                         |
| ------------------------- | ------- | ------------------------------------------------------------ |
| `reserved:unknown`        | 0       | 无法推导出身份。                                             |
| `reserved:host`           | 1       | 本地主机。源自或指定到本地主机 IP 之一的任何流量。           |
| `reserved:world`          | 2       | 集群外的任何网络端点。                                       |
| `reserved:unmanaged`      | 3       | 不受 Cilium 管理的端点，例如在安装 Cilium 之前启动的 Kubernetes pod。 |
| `reserved:health`         | 4       | 这是 Cilium 代理生成的健康检查流量。                         |
| `reserved:init`           | 5       | 尚未解析身份的端点被分配了初始身份。这代表了一个端点的阶段，在该阶段中，派生安全身份所需的一些元数据仍然缺失。这通常是引导阶段的情况。仅当端点的标签在创建时未知时才分配初始化标识。Docker 插件可能就是这种情况。 |
| `reserved:remote-node`    | 6       | 所有远程集群主机的集合。源自或指定到任何连接集群中任何主机的 IP 之一的任何流量，而不是本地节点。 |
| `reserved:kube-apiserver` | 7       | 具有为 kube-apiserver 运行的后端的远程节点。                 |

{{<callout note 提示>}}
Cilium 曾经在 `reserved:host` 身份中同时包含本地和所有远程主机。除非使用最近的默认 ConfigMap，否则这仍然是默认选项。可以通过 `enable-remote-node-identity` 选项启用远程节点身份。
{{</callout>}}

### 知名身份

以下是 Cilium 自动识别的知名身份列表，Cilium 将分发安全身份，而无需联系任何外部依赖项，例如 kvstore。这样做的目的是允许引导 Cilium 并通过集群中的策略强制实现网络连接，以实现基本服务，而无需任何依赖项。

| 部署            | 命名空间        | 服务账户        | 集群名称       | 数字 ID | 标签                                                      |
| --------------- | --------------- | --------------- | -------------- | ------- | --------------------------------------------------------- |
| kube-dns        | kube-system     | kube-dns        | cilium-cluster | 102     | `k8s-app=kube-dns`                                        |
| kube-dns（EKS） | kube-system     | kube-dns        | cilium-cluster | 103     | `k8s-app=kube-dns`,`eks.amazonaws.com/component=kube-dns` |
| core-dns        | kube-system     | coredns         | cilium-cluster | 104     | `k8s-app=kube-dns`                                        |
| core-dns（EKS） | kube-system     | coredns         | cilium-cluster | 106     | `k8s-app=kube-dns`,`eks.amazonaws.com/component=coredns`  |
| cilium-operator | cilium-namspace | cilium-operator | cilium-cluster | 105     | `name=cilium-operator`,`io.cilium/app=operator`           |

{{<callout>}}
如果 `cilium-cluster` 未定义该 `cluster-name` 选项，则默认值将设置为  `default`。
{{</callout>}}

### 集群中的身份管理 {#dentity-management-in-the-cluster}

身份在整个集群中都是有效的，这意味着如果在多个集群节点上启动了多个 pod 或容器，如果它们共享身份相关标签，那么它们都将解析并共享同一个身份。这需要集群节点之间的协调。

![集群中的身份管理示意图](../../images/identity_store.png "集群中的身份管理示意图")

解析端点身份的操作是在分布式键值存储的帮助下执行的，如果之前没有看到以下值，则允许以生成新的唯一标识符的形式执行原子操作。这允许每个集群节点创建与身份相关的标签子集，然后查询键值存储以派生身份。根据之前是否查询过这组标签，要么创建一个新的身份，要么返回初始查询的身份。

## 节点 {#node}

Cilium 将节点称为集群的单个成员。每个节点都必须运行 `cilium-agent` 并且将以自主的方式运行。为了简单和规模化，在不同节点上运行的 Cilium 代理之间的状态同步保持在最低限度。它仅通过键值存储或数据包元数据发生。

### 节点地址 {#node-address}

Cilium 会自动检测节点的 IPv4 和 IPv6 地址。当 `cilium-agent` 启动时打印出检测到的节点地址：

```ini
Local node-name: worker0
Node-IPv6: f00d::ac10:14:0:1
External-Node IPv4: 172.16.0.20
Internal-Node IPv4: 10.200.28.238
```
