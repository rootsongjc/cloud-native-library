---
weight: 1
title: 组件概览
date: '2022-06-07T12:00:00+08:00'
type: book
---

本文将为你介绍 Cilium 和 Hubble 部署中包含的组件。

Cilium 包含以下组件：

- 代理
- 客户端
- Operator
- CNI 插件

Hubble 包含以下组件：

- 服务器
- 中继器
- 客户端
- 图形用户界面
- eBPF

另外你还需要一个数据库来存储代理的状态。

下图展示的 Cilium 部署的组件。

![Cilium 组件示意图](../../images/cilium-arch.png "Cilium 组件示意图")

## Cilium

**代理**

Cilium 代理（`cilium-agent`）在集群的每个节点上运行。在高层次上，代理接受通过 Kubernetes 或 API 的配置，描述网络、服务负载均衡、网络策略、可视性和监控要求。

Cilium 代理监听来自编排系统（如 Kubernetes）的事件，以了解容器或工作负载的启动和停止时间。它管理 eBPF 程序，Linux 内核用它来控制这些容器的所有网络访问。

**客户端（CLI）**

Cilium CLI 客户端（`cilium`）是一个命令行工具，与 Cilium 代理一起安装。它与运行在同一节点上的 Cilium 代理的 REST API 互动。CLI 允许检查本地代理的状态。它还提供工具，直接访问 eBPF map 以验证其状态。

**Operator**

Cilium Operator 负责管理集群中的职责，这些职责在逻辑上应该是为整个集群处理一次，而不是为集群中的每个节点处理一次。Cilium Operator 不在任何转发或网络策略决定的关键路径上。如果 Operator 暂时不可用，集群一般会继续运作。然而，根据配置的不同，Operator 的可用性失败可能导致：

- IP 地址管理（IPAM）的延迟，因此，如果 Operator 需要分配新的 IP 地址，那么新工作负载的调度也会延迟
- 未能更新 kvstore 的心跳密钥，这将导致代理宣布 kvstore 不健康并重新启动。

**CNI 插件**

CNI 插件（`cilium-cni`）由 Kubernetes 在一个节点上调度或终止 pod 时调用。它与节点的 Cilium API 交互，以触发必要的数据通路配置，为 pod 提供网络、负载均衡和网络策略。

## Hubble

**服务器**

Hubble 服务器在每个节点上运行，从 Cilium 检索基于 eBPF 的可见性。它被嵌入到 Cilium 代理中，以实现高性能和低开销。它提供一个 gRPC 服务来检索流量和 Prometheus 指标。

**中继器**

中继器（`hubble-relay`）是一个独立的组件，它知道所有正在运行的 Hubble 服务器，并通过连接它们各自的 gRPC API 和提供代表集群中所有服务器的 API，提供集群范围内的可见性。

**客户端（CLI）**

Hubble CLI（`hubble`）是一个命令行工具，能够连接到 `hubble-relay` 的 gRPC API 或本地服务器来检索流量事件。

**图形用户界面（GUI）**

图形用户界面（`hubble-ui`）利用基于中继的可见性，提供一个图形化的服务依赖性和连接图。

**eBPF**

eBPF 是一个 Linux 内核字节码解释器，最初是用来过滤网络数据包的，例如 tcpdump 和 socket 过滤器。此后，它被扩展为额外的数据结构，如 hashtable 和数组，以及额外的动作，以支持数据包的处理、转发、封装等。内核验证器确保 eBPF 程序安全运行，JIT 编译器将字节码转换为 CPU 架构的特定指令，以提高本地执行效率。eBPF 程序可以在内核的各种钩点上运行，如传入和传出数据包。

eBPF 继续发展，并在每个新的 Linux 版本中获得额外的功能。Cilium 利用 eBPF 来执行核心数据通路过滤、处理、监控和重定向，并要求 eBPF 的功能在任何 Linux 内核 4.8.0 或更新的版本中。基于 4.8.x 已经宣布终结，4.9.x 已经被提名为稳定版本，我们建议至少运行内核 4.9.17（截至本文撰写时，当前最新的稳定 Linux 内核是 4.10.x）。

Cilium 能够探测到 Linux 内核的可用功能，并在探测到时自动利用更多的最新功能。

## 数据存储

Cilium 需要一个数据存储来传播代理之间的状态。它支持以下数据存储：

**Kubernetes CRD（默认）**

存储任何数据和传播状态的默认选择是使用 Kubernetes 自定义资源定义（CRD）。CRD 由 Kubernetes 提供，用于集群组件通过 Kubernetes 资源表示配置和状态。

**键值存储**

在 Cilium 的默认配置中配置的 Kubernetes CRD 可以满足状态存储和传播的所有要求。键值存储可以选择作为一种优化，以提高集群的可扩展性，因为直接使用键值存储的变化通知和存储要求更有效率。

目前支持的键值存储是：

- [etcd](https://github.com/etcd-io/etcd)

{{<callout note 提示>}}
可以直接利用 Kubernetes 的 etcd 集群或维护一个专门的 etcd 集群。
{{</callout>}}
