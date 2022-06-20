---
weight: 1
title: 网络策略模式
date: '2022-06-07T12:00:00+08:00'
type: book
---

Cilium 代理（agent）和 Cilium 网络策略的配置决定了一个端点（Endpoint）是否接受来自某个来源的流量。代理可以进入以下三种策略执行模式：

- **default**

  如果任何规则选择了一个 Endpoint 并且该规则有一个入口部分，那么该端点就会在入口处进入默认拒绝状态。如果任何规则选择了一个 Endpoint 并且该规则有一个出口部分，那么该端点就会在出口处进入默认拒绝状态。这意味着端点开始时没有任何限制，一旦有规则限制其在入口处接收流量或在出口处传输流量的能力，那么端点就会进入白名单模式，所有流量都必须明确允许。

- **always**

  在 always 模式下，即使没有规则选择特定的端点，也会在所有端点上启用策略执行。如果你想配置健康实体，在启动 cilium-agent 时用 `enable-policy=always` 检查整个集群的连接性，你很可能想启用与健康端点的通信。

- **never**

  在 “never" 模式下，即使规则选择了特定的端点，所有端点上的策略执行也被禁用。换句话说，所有流量都允许来自任何来源（入口处）或目的地（出口处）。

要在运行时为 Cilium 代理管理的所有端点配置策略执行模式，请使用：

```bash
$ cilium config PolicyEnforcement={default,always,never}
```

如果你想在启动时为一个特定的代理配置策略执行模式，在启动 Cilium 守护程序时提供以下标志：

```bash
$ cilium-agent --enable-policy={default,always,never} [...]
```

同样，你可以通过在 Cilium DaemonSet 中加入上述参数来启用整个 Kubernetes 集群的策略执行模式：

```yaml
- name: CILIUM_ENABLE_POLICY
  value: always
```

## 规则基础知识

所有策略规则都是基于白名单模式，也就是说，策略中的每条规则都允许与该规则相匹配的流量。如果存在两条规则，其中一条可以匹配更广泛的流量，那么所有匹配更广泛规则的流量都将被允许。如果两个或更多的规则之间有一个交叉点，那么与这些规则的结合点相匹配的流量将被允许。最后，如果流量不匹配任何规则，它将根据网络策略执行模式被丢弃。

策略规则共享一个共同的基本类型，指定规则适用于哪些端点，并共享元数据以识别规则。每条规则都被分割成一个入口部分和一个出口部分。入口部分包含必须应用于进入端点的流量的规则，出口部分包含应用于来自匹配端点选择器的端点的流量的规则。可以提供入口、出口或两者。如果入口和出口都被省略，规则就没有效果。

```go
type Rule struct {
        // EndpointSelector选择所有应该受此规则约束的端点。
        // EndpointSelector和NodeSelector不能同时为空，并且
        // 互相排斥。
        //
        // +optional
        EndpointSelector EndpointSelector `json: "endpointSelector,omitempty"`。

        // NodeSelector 选择所有应该受此规则约束的节点。
        // EndpointSelector和NodeSelector不能同时为空，并且相互排斥的。
        // 只能在CiliumClusterwideNetworkPolicies中使用。
        //
        // +optional
        NodeSelector EndpointSelector `json: "nodeSelector,omitempty"`。

        // Ingress是一个IngressRule的列表，它在Ingress时被强制执行。
        // 如果省略或为空，则此规则不适用于入口处。
        //
        // +optional
        Ingress []IngressRule `json: "ingress,omitempty"`。

        // Egress是一个在出口处执行的EgressRule的列表。
        // 如果省略或为空，该规则不适用于出口处。
        //
        // +optional
        Egress []EgressRule `json: "egress,omitempty"`

        // Labels 是一个可选的字符串列表，可以用来
        // 重新识别该规则或存储元数据。它可以根据标签来查询
        // 或删除基于标签的字符串。标签并不要求是
        // 唯一的，多个规则可以有重叠的或相同的标签。
        //
        // +optional
        Labels labels.LabelArray `json: "labels,omitempty"`

        // Description 是一个自由格式的字符串，它可以由规则的创建者使用。
        // 它可以被规则的创建者用来存储该规则目的的可读解释。
        // 规则不能通过注释来识别。
        //
        // +optional
        Description string `json: "description,omitempty"`.
}
```

**endpointSelector / nodeSelector**

选择策略规则所适用的端点或节点。策略规则将被应用于所有符合选择器中指定标签的端点。

**Ingress**

必须在端点入口处适用的规则列表，即适用于进入端点的所有网络数据包。

**Egress**

必须适用于端点出口的规则列表，即适用于离开端点的所有网络数据包。

**Lebels**

标签是用来识别规则的。规则可以通过标签列出和删除。通过以下方式导入的策略规则 kubernetes 自动获得 `io.cilium.k8s.policy.name=NAME` 的标签，其中 `NAME` 对应的是在 NetworkPolicy 或 CiliumNetworkPolicy 资源中指定的名称。

**Description**

描述是一个字符串，不被 Cilium 所解释。它可以用来以人类可读的形式描述规则的意图和范围。

## 端点选择器

端点选择器基于 [Kubernetes LabelSelector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/\#label-selectors)。它之所以被称为端点选择器，是因为它只适用于 Endpoint.

## 节点选择器

节点选择器也是基于端点选择器的，不过它不是与端点相关的标签相匹配，而是适用于与集群中的节点相关的标签。

节点选择器只能用在 CiliumClusterwideNetworkPolicy。请参阅 Host Policies 以了解关于节点级策略范围的详细信息。
