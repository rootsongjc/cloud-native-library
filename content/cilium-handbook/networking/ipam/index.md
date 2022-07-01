---
weight: 2
title: IP 地址管理（IPAM）
date: '2022-06-17T12:00:00+08:00'
type: book
---

IP 地址管理（IPAM）负责分配和管理由 Cilium 管理的网络端点（容器和其他）使用的 IP 地址。Cilium 支持以下各种 IPAM 模式，以满足不同用户的需求。

- [集群范围（默认）](#cluster-scope)
- [Kubernetes 主机范围](#kubernetes-host-scope)
- [Azure IPAM](https://docs.cilium.io/en/stable/concepts/networking/ipam/azure/)
- [AWS ENI](https://docs.cilium.io/en/stable/concepts/networking/ipam/eni/)
- [Google Kubernetes Engine](https://docs.cilium.io/en/stable/concepts/networking/ipam/gke/)
- [CRD 支持](#crd-backed)

## 集群范围{#cluster-scope}

集群范围 IPAM 模式将 PodCIDR 分配给每个节点，并使用每个节点上的主机范围分配器分配 IP。因此它类似于 [Kubernetes 主机范围](#kubernetes-host-scope)模式。区别在于 Kubernetes 不是通过 Kubernetes `v1.Node`资源分配每个节点的 PodCIDR，而是 Cilium Operator 通过 `v2.CiliumNode` 资源管理每个节点的 PodCIDR。这种模式的优点是它不依赖于 Kubernetes 被配置为分发每个节点的 PodCIDR。

### 架构

![架构图](cluster_pool.png "集群范围模式 IPAM 架构图")

如果无法将 Kubernetes 配置为分发 PodCIDR 或需要更多控制，这将非常有用。

在这种模式下，Cilium 代理将在启动时等待，直到 `PodCIDRs` 范围通过 Cilium 节点 `v2.CiliumNode` 对象，通过 `v2.CiliumNode` 中设置的资源字段为所有启用的地址族提供：

| 字段                 | 描述                         |
| -------------------- | ---------------------------- |
| `Spec.IPAM.PodCIDRs` | IPv4 和/或 IPv6 PodCIDR 范围 |

### 集群范围配置

有关如何在 Cilium 中启用此模式的实用教程，请参阅 [由 Cilium 集群池 IPAM 支持的 CRD](https://docs.cilium.io/en/stable/gettingstarted/ipam-cluster-pool/#gsg-ipam-crd-cluster-pool)。

### 故障排除

#### 查找分配错误

检查 `Error` 字段中的 `Status.Operator` 字段：

```bash
kubectl get ciliumnodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.operator.error}{"\n"}{end
```

## Kubernetes 主机范围{#kubernetes-host-scope}

Kubernetes 主机范围 IPAM 模式启用 `ipam: kubernetes` 并将地址分配委托给集群中的每个单独节点。Kubernetes 分配的 IP 超出了与每个节点关联的 `PodCIDR` 范围。

![架构图](k8s_hostscope.png "Kubernetes 主机范围模式 IPAM 架构图")

在这种模式下，Cilium 代理将在启动时等待，直到 `PodCIDR` 范围通过 Kubernetes `v1.Node` 对象通过以下方法之一为所有启用的地址家族提供：

**通过 v1.Node 资源字段**

| 字段            | 描述                           |
| --------------- | ------------------------------ |
| `spec.podCIDRs` | IPv4 和 / 或 IPv6 PodCIDR 范围 |
| `spec.podCIDR`  | IPv4 或 IPv6 PodCIDR 范围      |

{{<callout note 提示>}}
`kube-controller-manager` 使用 `--allocate-node-cidrs` 标志运行 `kube-controller-manager` 以指示 Kubernetes  应该分配的 PodCIDR 范围。
{{</callout>}}

**通过 v1.Node 注释**

| 注解                                 | 描述                           |
| ------------------------------------ | ------------------------------ |
| `io.cilium.network.ipv4-pod-cidr`    | IPv4 PodCIDR 范围              |
| `io.cilium.network.ipv6-pod-cidr`    | IPv6 PodCIDR 范围              |
| `io.cilium.network.ipv4-cilium-host` | cilium 主机接口的 IPv4 地址    |
| `io.cilium.network.ipv6-cilium-host` | cilium 主机接口的 IPv6 地址    |
| `io.cilium.network.ipv4-health-ip`   | cilium-health 端点的 IPv4 地址 |
| `io.cilium.network.ipv6-health-ip`   | cilium-health 端点的 IPv6 地址 |

{{<callout note>}}
基于注解的机制主要与旧的 Kubernetes 版本结合使用，这些版本尚不支持`spec.podCIDRs`但同时支持 IPv4 和 IPv6。
{{</callout>}}

### 主机范围配置

存在以下 ConfigMap 选项来配置 Kubernetes 主机范围：

- `ipam: kubernetes`：启用 Kubernetes IPAM 模式。启用此选项将自动启用`k8s-require-ipv4-pod-cidr` 如何  `enable-ipv4` 是 `true` 和 `k8s-require-ipv6-pod-cidr` 如何  `enable-ipv6` 是  `true`。
- `k8s-require-ipv4-pod-cidr: true`：指示 Cilium 代理等待，直到 IPv4 PodCIDR 通过 Kubernetes 节点资源可用。
- `k8s-require-ipv6-pod-cidr: true`：指示 Cilium 代理等待，直到 IPv6 PodCIDR 通过 Kubernetes 节点资源可用。

使用 helm 之前的选项可以定义为：

- `ipam: kubernetes`：`--set ipam.mode=kubernetes`
- `k8s-require-ipv4-pod-cidr: true`：`--set k8s.requireIPv4PodCIDR=true`， 仅适用于 `--set ipam.mode=kubernetes`
- `k8s-require-ipv6-pod-cidr: true`：`--set k8s.requireIPv6PodCIDR=true`，仅适用于 `--set ipam.mode=kubernetes`

## CRD 支持{#crd-backed}

CRD 支持的 IPAM 模式提供了一个可扩展的接口，以通过 Kubernetes 自定义资源定义 (CRD) 控制 IP 地址管理。这允许将 IPAM 委托给外部运营商或使其用户可配置每个节点。

### 架构

![../../../../_images/crd_arch.png](https://tva1.sinaimg.cn/large/e6c9d24ely1h3bbtsnex0j20lv06yaan.jpg)

启用此模式后，每个 Cilium 代理将开始监视 `ciliumnodes.cilium.io`名称与运行代理的 Kubernetes 节点匹配的 Kubernetes 自定义资源。

每当更新自定义资源时，每个节点的分配池都会更新为 `spec.ipam.available` 字段中列出的所有地址。移除当前分配的 IP 后，该 IP 将继续使用，但在释放后无法重新分配。

在分配池中分配 IP 后，将 IP 添加到  `status.ipam.inuse` 字段中。

{{<callout note 提示>}}
节点状态更新被限制为最多每 15 秒运行一次。因此，如果同时调度多个 Pod，状态部分的更新可能会滞后。
{{</callout>}}

### CRD 支持配置

通过在 `cilium-config` ConfigMap 中设置 `ipam: crd` 或指定选项 `--ipam=crd`，可以启用 CRD 支持的 IPAM 模式。启用后，代理将等待与 Kubernetes 节点名称相匹配的 `CiliumNode` 自定义资源变得可用，并且至少有一个 IP 地址被列为可用。当连接性健康检查被启用时，必须有至少两个 IP 地址可用。

在等待期间，代理将打印以下日志消息：

```
Waiting for initial IP to become available in '<node-name>' custom resource
```

有关如何使用 Cilium 启用 CRD IPAM 模式的实用教程，请参阅 [CRD 支持的 IPAM](https://docs.cilium.io/en/stable/gettingstarted/ipam-crd/#gsg-ipam-crd)部分。

### 权限

为了使自定义资源发挥作用，需要以下额外权限。使用标准 Cilium 部署工件时会自动授予这些权限：

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cilium
rules:
- apiGroups:
  - cilium.io
  resources:
  - ciliumnodes
  - ciliumnodes/status
  verbs:
  - '*'
```

## CRD 定义

`CilumNode` 自定义资源以标准 Kubernetes 资源为模型，分为一个 `spec` 和 `status` 部分：

```go
type CiliumNode struct {
        [...]

        // Spec is the specification of the node
        Spec NodeSpec `json:"spec"`

        // Status it the status of the node
        Status NodeStatus `json:"status"`
}
```

### IPAM 规范

该 `spec` 部分嵌入了一个 IPAM 特定字段，该字段允许定义节点可用于分配的所有 IP 的列表：

```go
// AllocationMap is a map of allocated IPs indexed by IP
type AllocationMap map[string]AllocationIP

// NodeSpec is the configuration specific to a node
type NodeSpec struct {
        // [...]

        // IPAM is the address management specification. This section can be
        // populated by a user or it can be automatically populated by an IPAM
        // operator
        //
        // +optional
        IPAM IPAMSpec `json:"ipam,omitempty"`
}

// IPAMSpec is the IPAM specification of the node
type IPAMSpec struct {
        // Pool is the list of IPs available to the node for allocation. When
        // an IP is used, the IP will remain on this list but will be added to
        // Status.IPAM.InUse
        //
        // +optional
        Pool AllocationMap `json:"pool,omitempty"`
}

// AllocationIP is an IP available for allocation or already allocated
type AllocationIP struct {
        // Owner is the owner of the IP, this field is set if the IP has been
        // allocated. It will be set to the pod name or another identifier
        // representing the usage of the IP
        //
        // The owner field is left blank for an entry in Spec.IPAM.Pool
        // and filled out as the IP is used and also added to
        // Status.IPAM.InUse.
        //
        // +optional
        Owner string `json:"owner,omitempty"`

        // Resource is set for both available and allocated IPs, it represents
        // what resource the IP is associated with, e.g. in combination with
        // AWS ENI, this will refer to the ID of the ENI
        //
        // +optional
        Resource string `json:"resource,omitempty"`
}
```

### IPAM 状态

该 `status `部分包含一个 IPAM 特定字段。IPAM 状态报告该节点上所有使用的地址：

```go
// NodeStatus is the status of a node
type NodeStatus struct {
        // [...]

        // IPAM is the IPAM status of the node
        //
        // +optional
        IPAM IPAMStatus `json:"ipam,omitempty"`
}

// IPAMStatus is the IPAM status of a node
type IPAMStatus struct {
        // InUse lists all IPs out of Spec.IPAM.Pool which have been
        // allocated and are in use.
        //
        // +optional
        InUse AllocationMap `json:"used,omitempty"`
}
```

## 技术详解{#technical-deep-dive}

### Cilium 容器网络控制流程

下面的控制流程图概述了端点如何为 Cilium 支持的每种不同的地址管理模式从 IPAM 获取其 IP 地址。

![流程图](cilium_container_networking_control_flow.png "Cilium 容器网络控制流程图")
