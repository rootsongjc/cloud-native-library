---
weight: 3
title: 端点生命周期
date: '2022-06-17T12:00:00+08:00'
type: book
---

本节指定 Cilium 端点的生命周期。

Cilium 中的端点状态包括：

- `restoring`：端点在 Cilium 启动之前启动，Cilium 正在恢复其网络配置。
- `waiting-for-identity`：Cilium 正在为端点分配一个唯一的身份。
- `waiting-to-regenerate`：端点接收到一个身份并等待（重新）生成其网络配置。
- `regenerating`：正在（重新）生成端点的网络配置。这包括为该端点编程 eBPF。
- `ready`：端点的网络配置已成功（重新）生成。
- `disconnecting`：正在删除端点。
- `disconnected`：端点已被删除。

![端点状态生命周期](../../images/cilium-endpoint-lifecycle.png "端点状态生命周期")

可以使用 `cilium endpoint list` 和 `cilium endpoint get` CLI 命令查询端点的状态。

当端点运行时，它会在 `waiting-for-identity`、`waiting-to-regenerate`、`regenerating` 和 `ready` 状态之间转换。进入 `waiting-for-identity` 状态的转换表明端点改变了它的身份。转换到 `waiting-to-regenerate` 或者 `regenerating` 状态表示要在端点上实施的策略由于身份、策略或配置的更改而发生了更改。

端点在被删除时转换为 `disconnecting`  状态，无论其当前状态如何。

## 初始化标识

在某些情况下，Cilium 无法在端点创建时立即确定端点的标签，因此无法在此时为端点分配身份。在知道端点的标签之前，Cilium 会暂时将一个特殊的单一标签 `reserved:init` 与端点相关联。当端点的标签变得已知时，Cilium 然后用端点的标签替换那个特殊的标签，并为端点分配一个适当的身份。

这可能在以下情况下在端点创建期间发生：

- 通过 libnetwork 使用 docker 运行 Cilium 
- 当 Kubernetes API 服务器不可用时使用 Kubernetes
- 在对应的 kvstore 不可用时处于 etcd 模式

要在初始化时允许进出端点的流量，您可以创建选择 `reserved:init` 标签的策略规则和/或允许进出特殊 `init` 实体的流量的规则。

例如，编写一个规则，允许所有初始化端点从主机接收连接并执行 DNS 查询，可以如下完成：

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: init
specs:
  - endpointSelector:
      matchLabels:
        "reserved:init": ""
    ingress:
    - fromEntities:
      - host
    egress:
    - toEntities:
      - all
      toPorts:
      - ports:
        - port: "53"
          protocol: UDP
```

同样，编写允许端点接收来自初始化端点的 DNS 查询的规则可以如下完成：

```yaml
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: "from-init"
spec:
  endpointSelector:
    matchLabels:
      app: myService
  ingress:
    - fromEntities:
      - init
    - toPorts:
      - ports:
        - port: "53"
          protocol: UDP
```

如果任何入口（`resp.egress`）策略规则选择了 `reserved:init` 标签，那么所有到（`resp.from`）初始化端点（这些规则未明确允许）的入口（`resp.egress`）流量都将被丢弃。否则，如果策略执行模式是 `never` 或 `default`，则允许所有入口（或出口）流量（或来自）初始化端点。否则，所有入口（或出口）流量都会被丢弃。
